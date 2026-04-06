import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/rsa_crypto.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

class ElementService {
  // Cache local des messages reçus pour l'historique
  static final Map<String, List<Map<String, dynamic>>> _receivedMessages = {};

  // Cache local des messages envoyés (plaintext) pour l'historique de session
  static final Map<String, List<Map<String, dynamic>>> _sentMessages = {};

  static Future<bool> sendElement({
    required String relationCode,
    required String type,
    required String value,
  }) async {
    debugPrint('=== sendElement START: relationCode=$relationCode, type=$type ===');
    final keyStore = RelationshipKeyStorage();

    // Retry loop for partner key (max 10s)
    String? partnerKey;
    String? partnerRelCode;
    int retries = 0;
    while (retries < 20) {
      partnerKey = await keyStore.readPartnerPublicKey(relationCode);
      partnerRelCode = await keyStore.readPartnerRelationCode(relationCode);
      debugPrint('Key check #$retries: partnerKey=${partnerKey != null}, partnerRelCode=$partnerRelCode');
      if (partnerKey != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (partnerKey == null) {
      debugPrint('❌ Partner key still missing after 10s retries');
      return false;
    }
    debugPrint('✅ Partner key ready (${partnerKey.length} chars)');

    String encrypted;
    bool isFakeKey = kIsWeb || partnerKey.contains('FAKE-WEB-KEY');

    if (isFakeKey) {
      encrypted = base64Encode(utf8.encode(value));
      debugPrint('Mode web/fake : message encodé en base64');
    } else {
      encrypted = RsaCrypto.encrypt(value, partnerKey);
      debugPrint('RSA encryption OK');
    }

    final payload = {
      'relationCode': relationCode,
      'partnerRelationCode': partnerRelCode ?? '',
      'key': type,
      'value': encrypted,
    };
    debugPrint('API payload: $payload');

    try {
      final response = await ApiClient.post('/element', payload);
      debugPrint('✅ API POST success: ${response.statusCode}');

      // CORRECTION : on ajoute un timestamp local pour éviter les collisions de clé de déduplication
      _sentMessages[relationCode] ??= [];
      _sentMessages[relationCode]!.add({
        'type': type,
        'value': value,
        'from': 'me',
        'isSent': true,
        'timestamp': DateTime.now().toIso8601String(), // ← timestamp local unique
      });
      return true;
    } catch (e) {
      debugPrint('❌ API POST failed: $e');
      return false;
    }
  }

  /// Fusionne une liste de messages en supprimant les doublons.
  /// Utilise un index de fallback pour éviter que les messages sans timestamp
  /// s'écrasent mutuellement.
  static List<Map<String, dynamic>> _mergeAndSort(
      List<Map<String, dynamic>> all) {
    final unique = <String, Map<String, dynamic>>{};
    int idx = 0;
    for (final msg in all) {
      // CORRECTION : si pas de timestamp, on utilise un index unique pour ne pas écraser
      final ts = msg['timestamp'] ?? 'local_$idx';
      final key = '${msg['type']}_${msg['value']}_${msg['from']}_$ts';
      unique[key] = msg;
      idx++;
    }
    final merged = unique.values.toList();
    merged.sort((a, b) {
      final ta = a['timestamp'];
      final tb = b['timestamp'];
      if (ta == null || tb == null) return 0;
      return ta.toString().compareTo(tb.toString());
    });
    return merged;
  }

  static Future<List<Map<String, dynamic>>> fetchElements(
      String myRelationCode) async {
    final keyStore = RelationshipKeyStorage();
    String? partnerCode;

    List<Map<String, dynamic>> sentMine =
        List<Map<String, dynamic>>.from(_sentMessages[myRelationCode] ?? []);
    List<Map<String, dynamic>> sentPartner = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> receivedMine =
        List<Map<String, dynamic>>.from(_receivedMessages[myRelationCode] ?? []);
    List<Map<String, dynamic>> receivedPartner = <Map<String, dynamic>>[];

    try {
      partnerCode = await keyStore.readPartnerRelationCode(myRelationCode);
      final fetchCode = partnerCode ?? myRelationCode;
      debugPrint('fetchElements: myCode=$myRelationCode, fetchCode=$fetchCode');

      if (partnerCode != null) {
        sentPartner = List<Map<String, dynamic>>.from(
            _sentMessages[partnerCode] ?? []);
        receivedPartner = List<Map<String, dynamic>>.from(
            _receivedMessages[partnerCode] ?? []);
      }

      final response = await ApiClient.get('/element?relationCode=$fetchCode');
      final decoded = jsonDecode(response.body);

      // Gérer tous les formats possibles de réponse
      final List? data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['elements'] is List) {
        data = decoded['elements'];
      } else {
        // Réponse invalide → retour sur l'historique local
        return _mergeAndSort([
          ...receivedMine,
          ...receivedPartner,
          ...sentMine,
          ...sentPartner,
        ]);
      }

      if (data == null || data.isEmpty) {
        return _mergeAndSort([
          ...receivedMine,
          ...receivedPartner,
          ...sentMine,
          ...sentPartner,
        ]);
      }

      final myPrivateKey = await keyStore.readPrivateKeyPem(myRelationCode);

      final received = data.map<Map<String, dynamic>>((e) {
        String decrypted = '';
        try {
          if (myPrivateKey == null) throw Exception('Clé privée manquante');

          if (kIsWeb || myPrivateKey.contains('FAKE-WEB-KEY')) {
            try {
              decrypted = utf8.decode(base64Decode(e['value']));
            } catch (_) {
              decrypted = e['value'] ?? '';
            }
          } else {
            try {
              decrypted = RsaCrypto.decrypt(e['value'], myPrivateKey);
            } catch (_) {
              try {
                decrypted = utf8.decode(base64Decode(e['value']));
              } catch (_) {
                decrypted = '[Erreur de déchiffrement]';
              }
            }
          }
        } catch (_) {
          decrypted = '[Erreur de déchiffrement]';
        }

        return {
          'type': e['type'] ?? e['key'],
          'value': decrypted,
          'from': e['from'],
          'timestamp': e['timestamp'],
          'isSent': false,
        };
      }).toList();

      // Mettre à jour le cache local des messages reçus
      _receivedMessages[myRelationCode] = received;
      if (partnerCode != null) {
        _receivedMessages[partnerCode] = received;
      }

      return _mergeAndSort([
        ...receivedMine,
        ...receivedPartner,
        ...sentMine,
        ...sentPartner,
        ...received,
      ]);
    } catch (e) {
      debugPrint('Erreur fetch elements: $e');
      return _mergeAndSort([
        ...receivedMine,
        ...receivedPartner,
        ...sentMine,
        ...sentPartner,
      ]);
    }
  }
}