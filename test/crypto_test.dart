import 'package:flutter_test/flutter_test.dart';
import 'package:secureqrapplication/crypto/key_generator.dart';
import 'package:secureqrapplication/crypto/rsa_crypto.dart';

void main() {
  test('Test generation de cles RSA en PEM', () {
    Map<String, String> keys = MyKeyGenerator.generateKeyPair();
    
    expect(keys['public'], isNotNull);
    expect(keys['private'], isNotNull);
    
    // verifie que c'est bien du PEM (peut etre RSA PUBLIC KEY ou PUBLIC KEY)
    expect(keys['public']!.contains('-----BEGIN'), isTrue);
    expect(keys['private']!.contains('-----BEGIN'), isTrue);
    
    print('Public key (PEM):');
    print(keys['public']);
  });

  test('Test chiffrement et dechiffrement avec PEM', () {
    // on genere les cles
    Map<String, String> keys = MyKeyGenerator.generateKeyPair();
    String publicPem = keys['public']!;
    String privatePem = keys['private']!;
    
    String message = "Salut, ceci est un test !";
    
    // chiffre avec la cle publique
    String encrypted = RsaCrypto.encrypt(message, publicPem);
    print('Message chiffre: $encrypted');
    
    // dechiffre avec la cle privee
    String decrypted = RsaCrypto.decrypt(encrypted, privatePem);
    print('Message dechiffre: $decrypted');
    
    expect(decrypted, equals(message));
  });

  test('Test simulation Alice et Bob', () {
    // Alice genere ses cles
    Map<String, String> aliceKeys = MyKeyGenerator.generateKeyPair();
    
    // Bob genere ses cles
    Map<String, String> bobKeys = MyKeyGenerator.generateKeyPair();
    
    // Alice envoie un message a Bob
    // elle chiffre avec la cle publique de Bob
    String messageAlice = "Hello Bob !";
    String encrypted = RsaCrypto.encrypt(messageAlice, bobKeys['public']!);
    
    // Bob recoit et dechiffre avec sa cle privee
    String decrypted = RsaCrypto.decrypt(encrypted, bobKeys['private']!);
    
    expect(decrypted, equals(messageAlice));
    print('Alice -> Bob: $decrypted');
    
    // Bob repond a Alice
    String messageBob = "Salut Alice !";
    String encryptedBob = RsaCrypto.encrypt(messageBob, aliceKeys['public']!);
    String decryptedBob = RsaCrypto.decrypt(encryptedBob, aliceKeys['private']!);
    
    expect(decryptedBob, equals(messageBob));
    print('Bob -> Alice: $decryptedBob');
  });
}
