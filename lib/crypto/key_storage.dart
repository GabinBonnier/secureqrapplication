import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_generator.dart';

// stockage des cles avec flutter_secure_storage
class KeyStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // cles en memoire pour acces rapide
  static String? _myPublicKeyPem;
  static String? _myPrivateKeyPem;
  static String? _partnerPublicKeyPem;

  // genere et stocke nos cles
  static Future<void> generateMyKeys() async {
    Map<String, String> keys = MyKeyGenerator.generateKeyPair();
    _myPublicKeyPem = keys['public'];
    _myPrivateKeyPem = keys['private'];
    
    // on sauvegarde dans le secure storage
    await _storage.write(key: 'my_public_key', value: _myPublicKeyPem);
    await _storage.write(key: 'my_private_key', value: _myPrivateKeyPem);
    print("Cles sauvegardees");
  }

  // retourne notre cle publique (en PEM)
  static Future<String> getMyPublicKeyPem() async {
    if (_myPublicKeyPem == null) {
      // on essaie de charger depuis le storage
      _myPublicKeyPem = await _storage.read(key: 'my_public_key');
      if (_myPublicKeyPem == null) {
        // sinon on genere
        await generateMyKeys();
      }
    }
    return _myPublicKeyPem!;
  }

  // retourne notre cle privee (en PEM)
  static Future<String?> getMyPrivateKeyPem() async {
    if (_myPrivateKeyPem == null) {
      _myPrivateKeyPem = await _storage.read(key: 'my_private_key');
    }
    return _myPrivateKeyPem;
  }

  // stocke la cle publique du partenaire
  static void setPartnerPublicKeyPem(String publicKeyPem) {
    _partnerPublicKeyPem = publicKeyPem;
    print("Cle du partenaire enregistree");
  }

  // retourne la cle publique du partenaire
  static String? getPartnerPublicKeyPem() {
    return _partnerPublicKeyPem;
  }

  // verifie si on a nos cles
  static bool hasKeys() {
    return _myPublicKeyPem != null && _myPrivateKeyPem != null;
  }

  // verifie si on a la cle du partenaire
  static bool hasPartnerKey() {
    return _partnerPublicKeyPem != null;
  }

  // efface tout
  static Future<void> clearAll() async {
    _myPublicKeyPem = null;
    _myPrivateKeyPem = null;
    _partnerPublicKeyPem = null;
    await _storage.deleteAll();
    print("Cles effacees");
  }
}
