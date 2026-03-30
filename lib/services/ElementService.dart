import 'dart:convert';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/rsa_crypto.dart';
import 'package:secureqrapplication/crypto/relationship_key_storage.dart';

class ElementService {
	static Future<bool> sendElement({
		required String relationCode,
		required String type, // 'message', 'icone', ...
		required String value,
	}) async {
		try {
			// Chiffrement RSA avec la clé publique du partenaire (par relation)
			final keyStore = RelationshipKeyStorage();
			final partnerKey = await keyStore.readPartnerPublicKey(relationCode);
			if (partnerKey == null) throw Exception('Clé publique du partenaire manquante');
      final encrypted = RsaCrypto.encrypt(
        value,
        partnerKey,
      );
      final body = {
				'relationCode': relationCode,
				'type': type,
				'value': encrypted,
			};
			await ApiClient.post('/element', body);
			return true;
		} catch (e) {
			print('Erreur envoi element: $e');
			return false;
		}
	}

	// Récupère et déchiffre les éléments reçus
	static Future<List<Map<String, dynamic>>> fetchElements(String relationCode) async {
		try {
			final response = await ApiClient.get('/element?relationCode=$relationCode');
			final List data = jsonDecode(response.body);
			final keyStore = RelationshipKeyStorage();
			final myPrivateKey = await keyStore.readPrivateKeyPem(relationCode);
			final isWeb = identical(0, 0.0);
			return data.map<Map<String, dynamic>>((e) {
				String decrypted = '';
				try {
					if (myPrivateKey == null) throw Exception('Clé privée manquante');
          decrypted = RsaCrypto.decrypt(
            e['value'],
            myPrivateKey,
          );
        } catch (_) {
					if (isWeb) {
						// En mode web, afficher le message brut (base64 décodé) si possible
						try {
							decrypted = utf8.decode(base64Decode(e['value']));
						} catch (_) {
							decrypted = '[Erreur de déchiffrement]';
						}
					} else {
						decrypted = '[Erreur de déchiffrement]';
					}
				}
				return {
					'type': e['type'],
					'value': decrypted,
					'from': e['from'],
					'timestamp': e['timestamp'],
				};
			}).toList();
		} catch (e) {
			print('Erreur fetch elements: $e');
			return [];
		}
	}
}

