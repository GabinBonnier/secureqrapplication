import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';

// generation des cles RSA
class MyKeyGenerator {

  // genere le random securisé
  static FortunaRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final r = Random.secure();
    for (int i = 0; i < seed.length; i++) {
      seed[i] = r.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }

  // genere une paire de cles et retourne en format PEM
  static Map<String, String> generateKeyPair() {
    debugPrint("Generation des cles RSA...");

    final generator = RSAKeyGenerator();
    generator.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      _secureRandom(),
    ));

    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    // on convertit en PEM avec basic_utils
    String publicPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    String privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

    debugPrint("Cles generees !");
    
    return {
      'public': publicPem,
      'private': privatePem,
    };
  }
}
