import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';

// chiffrement et dechiffrement RSA
class RsaCrypto {

  // chiffre un message avec la cle publique du destinataire (en PEM)
  static String encrypt(String message, String publicKeyPem) {
    // on decode le PEM en objet RSAPublicKey
    RSAPublicKey publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
    
    // on utilise OAEP pour le chiffrement (plus secure)
    final engine = OAEPEncoding(RSAEngine());
    engine.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    
    // on chiffre
    final messageBytes = utf8.encode(message);
    final encrypted = engine.process(Uint8List.fromList(messageBytes));
    
    // on retourne en base64
    return base64Encode(encrypted);
  }

  // dechiffre un message avec notre cle privee (en PEM)
  static String decrypt(String encryptedBase64, String privateKeyPem) {
    // on decode le PEM
    RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
    
    final engine = OAEPEncoding(RSAEngine());
    engine.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    
    // on decode le base64 et on dechiffre
    final encryptedBytes = base64Decode(encryptedBase64);
    final decrypted = engine.process(Uint8List.fromList(encryptedBytes));
    
    return utf8.decode(decrypted);
  }
}
