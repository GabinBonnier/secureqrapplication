import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

class PairingService {

  static String? _myRelationCode;
  static String? _partnerRelationCode;

  // Crée un nouveau pairing (Alice)
  // Retourne le relationCode à mettre dans le QR
  static Future<String> createPairing() async {
    print("Creation du pairing...");
    try {
      String relationCode = const Uuid().v4();
      _myRelationCode = relationCode;
      print("Generated relationCode: $relationCode");

      final keyStore = RelationshipKeyStorage();
      await keyStore.generateAndSaveKeyPair(relationCode);
      print("Clés générées pour la relation $relationCode");

      String? myPublicKey = await keyStore.readPublicKeyPem(relationCode);
      if (myPublicKey == null) throw Exception('Clé publique non trouvée');
      print("Public key ready: ${myPublicKey.length} chars");

      final response = await ApiClient.post('/pairing', {
        'relationCode': relationCode,
        'userPublicKey': myPublicKey,
      });

      print("API POST success: ${response.statusCode} - ${response.body}");
      print("Pairing créé avec relationCode: $relationCode");
      return relationCode;
    } catch (e, stack) {
      print("ERROR createPairing: $e");
      print("Stack: $stack");
      rethrow;
    }
  }

  // Complète un pairing existant (Bob scanne le QR d'Alice)
  // relationCodeA = celui dans le QR d'Alice
  static Future<Map<String, dynamic>?> completePairing(String relationCodeA) async {
    print("Complétion du pairing $relationCodeA...");

    String relationCodeB = const Uuid().v4();
    _myRelationCode = relationCodeB;
    _partnerRelationCode = relationCodeA;

    final keyStore = RelationshipKeyStorage();
    await keyStore.generateAndSaveKeyPair(relationCodeB);
    print("Clés générées pour la relation $relationCodeB");

    String? myPublicKey = await keyStore.readPublicKeyPem(relationCodeB);
    if (myPublicKey == null) throw Exception('Clé publique non trouvée');

    try {
      final response = await ApiClient.put('/pairing', {
        'relationCodeA': relationCodeA,
        'relationCodeB': relationCodeB,
        'publicKeyB': myPublicKey,
      });

      final data = jsonDecode(response.body);

      // Bob reçoit la clé publique d'Alice → on la stocke sous relationCodeB
      // car Bob naviguera avec relationCodeB pour envoyer ses messages
      if (data['userPublicKey'] != null) {
        await keyStore.savePartnerPublicKey(relationCodeB, data['userPublicKey']);
        await keyStore.savePartnerRelationCode(relationCodeB, relationCodeA);
        print("Clé publique d'Alice + relCodeA enregistrés sous $relationCodeB !");
      }

      // On retourne relationCodeB pour que Bob navigue avec son propre code
      return {
        ...data,
        'relationCodeB': relationCodeB,
      };
    } catch (e) {
      print("Erreur completion: $e");
      return null;
    }
  }

  // Vérifie le statut du pairing (polling)
  static Future<String?> checkPairingStatus(String relationCode) async {
    try {
      print("Checking status for $relationCode...");
      final response = await ApiClient.get('/pairing/$relationCode/status');
      final data = jsonDecode(response.body);
      print("Status du pairing: ${data['status']}");
      return data['status']; // "waiting", "completed" ou "finalized"
    } catch (e, stack) {
      print("ERROR checkPairingStatus $relationCode: $e");
      print("Stack: $stack");
      return null;
    }
  }

  // Finalise le pairing (Alice, après détection "completed")
  static Future<Map<String, dynamic>?> finalizePairing(String relationCodeA) async {
    print("Finalisation du pairing...");
    try {
      final response = await ApiClient.delete('/pairing?relationCodeA=$relationCodeA');
      final data = jsonDecode(response.body);

      // Alice reçoit la clé publique de Bob → on la stocke sous relationCodeA
      // car Alice naviguera avec relationCodeA pour envoyer ses messages
      if (data['publicKeyB'] != null) {
        final keyStore = RelationshipKeyStorage();
        await keyStore.savePartnerPublicKey(relationCodeA, data['publicKeyB']);
        await keyStore.savePartnerRelationCode(relationCodeA, data['relationCodeB']);
        _partnerRelationCode = data['relationCodeB'];
        print("Clé publique de Bob + relCodeB enregistrés sous $relationCodeA !");
      }

      return data;
    } catch (e) {
      print("Erreur finalisation: $e");
      return null;
    }
  }

  /// Get stored partner relation code for a relationId (persistent)
  static Future<String?> getPartnerRelationCode(String relationId) async {
    final keyStore = RelationshipKeyStorage();
    return await keyStore.readPartnerRelationCode(relationId);
  }

  // Getters
  static String? get myRelationCode => _myRelationCode;
  static String? get partnerRelationCode => _partnerRelationCode;
}
