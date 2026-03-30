import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/rsa_crypto.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

class ElementService {

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
    while (retries < 20) {  // 20 * 0.5s = 10s
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
      return true;
    } catch (e) {
      debugPrint('❌ API POST failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchElements(String myRelationCode) async {
    try {
      // On fetch avec le code du PARTENAIRE pour récupérer les messages qu'il nous a envoyés
      final keyStore = RelationshipKeyStorage();
      final partnerCode = await keyStore.readPartnerRelationCode(myRelationCode);
      final fetchCode = partnerCode ?? myRelationCode;
      debugPrint('fetchElements: myCode=$myRelationCode, fetchCode=$fetchCode');

      final response = await ApiClient.get('/element?relationCode=$fetchCode');
      final decoded = jsonDecode(response.body);

      // Gérer tous les formats possibles de réponse
      final List? data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['elements'] is List) {
        data = decoded['elements'];
      } else {
        return [];
      }

      if (data == null || data.isEmpty) return [];

      final myPrivateKey = await keyStore.readPrivateKeyPem(myRelationCode);

      return data.map<Map<String, dynamic>>((e) {
        String decrypted = '';
        try {
          if (myPrivateKey == null) throw Exception('Clé privée manquante');

          if (kIsWeb || myPrivateKey.contains('FAKE-WEB-KEY')) {
            // Clé factice (web) → décodage base64
            try {
              decrypted = utf8.decode(base64Decode(e['value']));
            } catch (_) {
              decrypted = e['value'] ?? '';
            }
          } else {
            // Clé RSA réelle → tenter RSA, sinon fallback base64
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
          'type': e['type'],
          'value': decrypted,
          'from': e['from'],
          'timestamp': e['timestamp'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Erreur fetch elements: $e');
      return [];
    }
  }
}