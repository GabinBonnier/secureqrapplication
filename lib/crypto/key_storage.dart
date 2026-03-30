import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_generator.dart';
import 'package:flutter/foundation.dart';

class KeyStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _myPublicKeyPem;
  static String? _myPrivateKeyPem;
  static String? _partnerPublicKeyPem;

  // Génère et stocke nos clés
  static Future<void> generateMyKeys() async {
    try {
      if (kIsWeb) {
        // Clé factice pour le web (pour démo UI)
        _myPublicKeyPem = '-----BEGIN PUBLIC KEY-----\nFAKE-WEB-KEY\n-----END PUBLIC KEY-----';
        _myPrivateKeyPem = '-----BEGIN PRIVATE KEY-----\nFAKE-WEB-KEY\n-----END PRIVATE KEY-----';
        await _storage.write(key: 'my_public_key', value: _myPublicKeyPem);
        await _storage.write(key: 'my_private_key', value: _myPrivateKeyPem);
        debugPrint('Clé factice générée pour le web.');
      } else {
        Map<String, String> keys = MyKeyGenerator.generateKeyPair();
        _myPublicKeyPem = keys['public'];
        _myPrivateKeyPem = keys['private'];
        await _storage.write(key: 'my_public_key', value: _myPublicKeyPem);
        await _storage.write(key: 'my_private_key', value: _myPrivateKeyPem);
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la génération des clés RSA: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // Retourne notre clé publique (PEM)
  static Future<String> getMyPublicKeyPem() async {
    if (_myPublicKeyPem == null) {
      _myPublicKeyPem = await _storage.read(key: 'my_public_key');
      if (_myPublicKeyPem == null) {
        await generateMyKeys();
      }
    }
    return _myPublicKeyPem!;
  }

  // Retourne notre clé privée
  static Future<String?> getMyPrivateKeyPem() async {
      // ignore: prefer_conditional_assignment
    if (_myPrivateKeyPem == null) {
      _myPrivateKeyPem = await _storage.read(key: 'my_private_key');
    }
    return _myPrivateKeyPem;
  }

  // Stocke la clé publique du partenaire
  static void setPartnerPublicKeyPem(String publicKeyPem) {
    _partnerPublicKeyPem = publicKeyPem;
  }

  // Retourne la clé publique du partenaire
  static String? getPartnerPublicKeyPem() {
    return _partnerPublicKeyPem;
  }

  // Vérifie si on a nos clés
  static bool hasKeys() {
    return _myPublicKeyPem != null && _myPrivateKeyPem != null;
  }

  // Vérifie si on a la clé du partenaire
  static bool hasPartnerKey() {
    return _partnerPublicKeyPem != null;
  }

  // Efface tout
  static Future<void> clearAll() async {
    _myPublicKeyPem = null;
    _myPrivateKeyPem = null;
    _partnerPublicKeyPem = null;
    await _storage.deleteAll();
  }
}