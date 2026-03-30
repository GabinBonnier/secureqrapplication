import 'package:flutter/foundation.dart';
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
    debugPrint("Creation du pairing...");
    try {
      String relationCode = const Uuid().v4();
      _myRelationCode = relationCode;
      debugPrint("Generated relationCode: $relationCode");

      final keyStore = RelationshipKeyStorage();
      await keyStore.generateAndSaveKeyPair(relationCode);
      debugPrint("Clés générées pour la relation $relationCode");

      String? myPublicKey = await keyStore.readPublicKeyPem(relationCode);
      if (myPublicKey == null) throw Exception('Clé publique non trouvée');
      debugPrint("Public key ready: ${myPublicKey.length} chars");

      final response = await ApiClient.post('/pairing', {
        'relationCode': relationCode,
        'userPublicKey': myPublicKey,
      });

      debugPrint("API POST success: ${response.statusCode} - ${response.body}");
      debugPrint("Pairing créé avec relationCode: $relationCode");
      return relationCode;
    } catch (e, stack) {
      debugPrint("ERROR createPairing: $e");
      debugPrint("Stack: $stack");
      rethrow;
    }
  }

  // Complète un pairing existant (Bob scanne le QR d'Alice)
  // relationCodeA = celui dans le QR d'Alice
  static Future<Map<String, dynamic>?> completePairing(String relationCodeA) async {
    debugPrint("Complétion du pairing $relationCodeA...");

    String relationCodeB = const Uuid().v4();
    _myRelationCode = relationCodeB;
    _partnerRelationCode = relationCodeA;

    final keyStore = RelationshipKeyStorage();
    await keyStore.generateAndSaveKeyPair(relationCodeB);
    debugPrint("Clés générées pour la relation $relationCodeB");

    String? myPublicKey = await keyStore.readPublicKeyPem(relationCodeB);
    if (myPublicKey == null) throw Exception('Clé publique non trouvée');

    try {
      final response = await ApiClient.put('/pairing', {
        'relationCodeA': relationCodeA,
        'relationCodeB': relationCodeB,
        'publicKeyB': myPublicKey,
      });

      final data = jsonDecode(response.body);
      debugPrint("PUT /pairing response body: $data");

      // Bob reçoit la clé publique d'Alice → on la stocke sous relationCodeB
      // car Bob naviguera avec relationCodeB pour envoyer ses messages
      final aliceKey = data['userPublicKey'] ?? data['publicKeyA'] ?? data['publicKey'];
      if (aliceKey != null) {
        await keyStore.savePartnerPublicKey(relationCodeB, aliceKey as String);
        await keyStore.savePartnerRelationCode(relationCodeB, relationCodeA);
        debugPrint("Clé publique d'Alice + relCodeA enregistrés sous $relationCodeB !");
      } else {
        debugPrint("❌ Clé publique d'Alice introuvable dans la réponse. Champs reçus: ${data.keys.toList()}");
      }

      // On retourne relationCodeB pour que Bob navigue avec son propre code
      return {
        ...data,
        'relationCodeB': relationCodeB,
      };
    } catch (e) {
      debugPrint("Erreur completion: $e");
      return null;
    }
  }

  // Vérifie le statut du pairing (polling)
  static Future<String?> checkPairingStatus(String relationCode) async {
    try {
      debugPrint("Checking status for $relationCode...");
      final response = await ApiClient.get('/pairing/$relationCode/status');
      final data = jsonDecode(response.body);
      debugPrint("Status du pairing: ${data['status']}");
      return data['status']; // "waiting", "completed" ou "finalized"
    } catch (e, stack) {
      debugPrint("ERROR checkPairingStatus $relationCode: $e");
      debugPrint("Stack: $stack");
      return null;
    }
  }

  // Finalise le pairing (Alice, après détection "completed")
  static Future<Map<String, dynamic>?> finalizePairing(String relationCodeA) async {
    debugPrint("Finalisation du pairing...");
    try {
      final response = await ApiClient.delete('/pairing?relationCodeA=$relationCodeA');
      final data = jsonDecode(response.body);
      debugPrint("DELETE /pairing response body: $data");

      // Alice reçoit la clé publique de Bob → on la stocke sous relationCodeA
      // car Alice naviguera avec relationCodeA pour envoyer ses messages
      final bobKey = data['publicKeyB'] ?? data['publicKey'] ?? data['userPublicKey'];
      final bobRelCode = data['relationCodeB'] ?? data['relationCode'];
      if (bobKey != null && bobRelCode != null) {
        final keyStore = RelationshipKeyStorage();
        await keyStore.savePartnerPublicKey(relationCodeA, bobKey as String);
        await keyStore.savePartnerRelationCode(relationCodeA, bobRelCode as String);
        _partnerRelationCode = bobRelCode;
        debugPrint("Clé publique de Bob + relCodeB enregistrés sous $relationCodeA !");
      } else {
        debugPrint("❌ Clé/code de Bob introuvable dans la réponse. Champs reçus: ${data.keys.toList()}");
      }

      return data;
    } catch (e) {
      debugPrint("Erreur finalisation: $e");
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
