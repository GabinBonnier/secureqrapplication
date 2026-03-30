import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

// service pour gerer le pairing entre 2 appareils
class PairingService {
  
  static String? _myRelationCode;
  static String? _partnerRelationCode;

  // Crée un nouveau pairing
  // Retourne le relationCode à mettre dans le QR
  static Future<String> createPairing() async {
    print("Creation du pairing...");
    try {
      // on genere un UUID pour le relationCode
      String relationCode = const Uuid().v4();
      _myRelationCode = relationCode;
      print("Generated relationCode: $relationCode");

      // Génère et stocke la paire de clés pour cette relation
      final keyStore = RelationshipKeyStorage();
      await keyStore.generateAndSaveKeyPair(relationCode);
      print("Clés générées pour la relation $relationCode");

      // on recupere notre cle publique
      print("Getting public key...");
      String? myPublicKey = await keyStore.readPublicKeyPem(relationCode);
      if (myPublicKey == null) throw Exception('Clé publique non trouvée');
      print("Public key ready: ${myPublicKey.length} chars");

      // on envoie au serveur
      print("Calling API POST /pairing...");
      final response = await ApiClient.post('/pairing', {
        'relationCode': relationCode,
        'userPublicKey': myPublicKey,
      });

      print("API POST success: ${response.statusCode} - ${response.body}");
      print("Pairing cree avec relationCode: $relationCode");
      return relationCode;
    } catch (e, stack) {
      print("ERROR createPairing: $e");
      print("Stack: $stack");
      rethrow;
    }
  }

  // Complète un pairing existant
  // relationCodeA = celui dans le QR
  static Future<Map<String, dynamic>?> completePairing(String relationCodeA) async {
    print("Complétion du pairing $relationCodeA...");
    // on genere notre propre relationCode
    String relationCodeB = const Uuid().v4();
    _myRelationCode = relationCodeB;
    _partnerRelationCode = relationCodeA;

    // Génère et stocke la paire de clés pour cette relation
    final keyStore = RelationshipKeyStorage();
    await keyStore.generateAndSaveKeyPair(relationCodeB);
    print("Clés générées pour la relation $relationCodeB");

    // on recupere notre cle publique
    String? myPublicKey = await keyStore.readPublicKeyPem(relationCodeB);
    if (myPublicKey == null) throw Exception('Clé publique non trouvée');

    try {
      // PUT /pairing avec les 3 infos
      final response = await ApiClient.put('/pairing', {
        'relationCodeA': relationCodeA,
        'relationCodeB': relationCodeB,
        'publicKeyB': myPublicKey,
      });

      final data = jsonDecode(response.body);

      // On récupère la clé publique du partenaire
      if (data['userPublicKey'] != null) {
        await keyStore.savePartnerPublicKey(relationCodeB, data['userPublicKey']);
        print("Clé publique du partenaire enregistrée pour la relation $relationCodeB !");
      }

      return data;
    } catch (e) {
      print("Erreur completion: $e");
      return null;
    }
  }

  // verifie le status du pairing (polling)
  static Future<String?> checkPairingStatus(String relationCode) async {
    try {
      print("Checking status for $relationCode...");
      final response = await ApiClient.get('/pairing/$relationCode/status');
      final data = jsonDecode(response.body);
      print("Status response: ${data['status']}");
      return data['status']; // "waiting", "completed" ou "finalized"
    } catch (e, stack) {
      print("ERROR checkPairingStatus $relationCode: $e");
      print("Stack: $stack");
      return null;
    }
  }

  // recupere les infos
  static Future<Map<String, dynamic>?> finalizePairing(String relationCodeA) async {
    print("Finalisation du pairing...");
    
    try {
      final response = await ApiClient.delete('/pairing?relationCodeA=$relationCodeA');
      final data = jsonDecode(response.body);
      
      // On récupère la clé publique et le relationCode du partenaire
      if (data['publicKeyB'] != null && data['relationCodeB'] != null) {
        final keyStore = RelationshipKeyStorage();
        await keyStore.savePartnerPublicKey(data['relationCodeB'], data['publicKeyB']);
        _partnerRelationCode = data['relationCodeB'];
        print("Clé publique du partenaire enregistrée pour la relation ${data['relationCodeB']} !");
      }
      
      return data;
    } catch (e) {
      print("Erreur finalisation: $e");
      return null;
    }
  }

  // getters pour les relationCodes
  static String? get myRelationCode => _myRelationCode;
  static String? get partnerRelationCode => _partnerRelationCode;
}
