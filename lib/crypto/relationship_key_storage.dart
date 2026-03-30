import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_generator.dart';
import 'package:flutter/foundation.dart';

/// Stocke une paire de clés RSA par relation (relationCode)
class RelationshipKeyStorage {
  final FlutterSecureStorage _storage;
  RelationshipKeyStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  String _pubKey(String relationId) => 'rel:$relationId:pubPem';
  String _privKey(String relationId) => 'rel:$relationId:privPem';

  /// Génère et stocke une paire de clés pour une relation
  Future<void> generateAndSaveKeyPair(String relationId) async {
    if (kIsWeb) {
      // Clé factice pour le web (pour la démo UI)
      await _storage.write(key: _pubKey(relationId), value: '-----BEGIN PUBLIC KEY-----\nFAKE-WEB-KEY-$relationId\n-----END PUBLIC KEY-----');
      await _storage.write(key: _privKey(relationId), value: '-----BEGIN PRIVATE KEY-----\nFAKE-WEB-KEY-$relationId\n-----END PRIVATE KEY-----');
      print('Clé factice générée pour le web (relation $relationId)');
    } else {
      final keys = MyKeyGenerator.generateKeyPair();
      await _storage.write(key: _pubKey(relationId), value: keys['public']);
      await _storage.write(key: _privKey(relationId), value: keys['private']);
    }
  }

  Future<String?> readPublicKeyPem(String relationId) =>
      _storage.read(key: _pubKey(relationId));

  Future<String?> readPrivateKeyPem(String relationId) =>
      _storage.read(key: _privKey(relationId));

  Future<void> savePartnerPublicKey(String relationId, String partnerPublicKeyPem) async {
    await _storage.write(key: 'rel:$relationId:partnerPubPem', value: partnerPublicKeyPem);
  }

  Future<String?> readPartnerPublicKey(String relationId) =>
      _storage.read(key: 'rel:$relationId:partnerPubPem');

  Future<void> clearKeys(String relationId) async {
    await _storage.delete(key: _pubKey(relationId));
    await _storage.delete(key: _privKey(relationId));
    await _storage.delete(key: 'rel:$relationId:partnerPubPem');
  }
}
