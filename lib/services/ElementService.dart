import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/rsa_crypto.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

class ElementService {
  // Cache des messages envoyés (plaintext, session uniquement)
  static final Map<String, List<Map<String, dynamic>>> _sentMessages = {};

  // Cache des messages reçus (accumulés, jamais réécrasés)
  static final Map<String, List<Map<String, dynamic>>> _receivedMessages = {};

  static Future<bool> sendElement({
    required String relationCode,
    required String type,
    required String value,
  }) async {
    debugPrint('=== sendElement: relationCode=$relationCode, type=$type ===');
    final keyStore = RelationshipKeyStorage();

    // Attendre la clé partenaire (max 10s)
    String? partnerKey;
    String? partnerRelCode;
    for (int i = 0; i < 20; i++) {
      partnerKey = await keyStore.readPartnerPublicKey(relationCode);
      partnerRelCode = await keyStore.readPartnerRelationCode(relationCode);
      if (partnerKey != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (partnerKey == null) {
      debugPrint('❌ Clé partenaire introuvable après 10s');
      return false;
    }

    // Chiffrement avec la clé publique du partenaire
    String encrypted;
    if (kIsWeb || partnerKey.contains('FAKE-WEB-KEY')) {
      encrypted = base64Encode(utf8.encode(value));
    } else {
      encrypted = RsaCrypto.encrypt(value, partnerKey);
    }

    // On envoie sur le relationCode DU PARTENAIRE
    final targetCode = partnerRelCode ?? relationCode;

    final payload = {
      'relationCode': targetCode,
      'key': type,
      'value': encrypted,
    };

    try {
      final response = await ApiClient.post('/element', payload);
      debugPrint('✅ Envoi OK: ${response.statusCode}');

      // Stocker en local pour affichage immédiat côté émetteur
      _sentMessages[relationCode] ??= [];
      _sentMessages[relationCode]!.add({
        'type': type,
        'value': value, // plaintext pour l'émetteur
        'isSent': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Envoi échoué: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchElements(
      String myRelationCode) async {
    final keyStore = RelationshipKeyStorage();
    final myPrivateKey = await keyStore.readPrivateKeyPem(myRelationCode);

    try {
      // On fetch sur MON relationCode : c'est là que l'autre dépose ses messages
      final response =
          await ApiClient.get('/element?relationCode=$myRelationCode');
      final decoded = jsonDecode(response.body);

      List rawData = [];
      if (decoded is List) {
        rawData = decoded;
      } else if (decoded is Map && decoded['elements'] is List) {
        rawData = decoded['elements'];
      }

      if (rawData.isNotEmpty) {
        for (final e in rawData) {
          String decrypted;
          try {
            if (myPrivateKey == null ||
                myPrivateKey.contains('FAKE-WEB-KEY') ||
                kIsWeb) {
              decrypted = utf8.decode(base64Decode(e['value']));
            } else {
              decrypted = RsaCrypto.decrypt(e['value'], myPrivateKey);
            }
          } catch (_) {
            decrypted = '[Erreur déchiffrement]';
          }

          final newMsg = {
            'type': e['type'] ?? e['key'],
            'value': decrypted,
            'isSent': false,
            'timestamp': e['timestamp'] ??
                DateTime.now().toIso8601String(),
          };

          // Accumulation : on n'ajoute que si pas déjà dans le cache
          // (clé de déduplication : type + value déchiffrée + timestamp)
          _receivedMessages[myRelationCode] ??= [];
          final dedupKey =
              '${newMsg['type']}_${newMsg['value']}_${newMsg['timestamp']}';
          final alreadyExists = _receivedMessages[myRelationCode]!.any((m) =>
              '${m['type']}_${m['value']}_${m['timestamp']}' == dedupKey);

          if (!alreadyExists) {
            _receivedMessages[myRelationCode]!.add(newMsg);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur fetch: $e');
    }

    final all = <Map<String, dynamic>>[
    ...(_sentMessages[myRelationCode] ?? []),
    ...(_receivedMessages[myRelationCode] ?? []),
    ];
    
    all.sort((a, b) {
    final ta = a['timestamp']?.toString() ?? '';
    final tb = b['timestamp']?.toString() ?? '';
    return ta.compareTo(tb);
    });
    return all;

    all.sort((a, b) {
      final ta = a['timestamp']?.toString() ?? '';
      final tb = b['timestamp']?.toString() ?? '';
      return ta.compareTo(tb);
    });

    return all;
  }
}