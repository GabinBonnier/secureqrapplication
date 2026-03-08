import 'dart:convert';
import 'package:secureqrapplication/services/ApiClient.dart';
import 'package:secureqrapplication/crypto/key_storage.dart';

// service pour gerer le pairing entre 2 appareils
class PairingService {
  
  // cree un nouveau pairing et retourne l'id
  static Future<String> createPairing() async {
    print("Creation du pairing...");
    
    // on recupere notre cle publique
    String myPublicKey = await KeyStorage.getMyPublicKeyPem();
    
    // on envoie au serveur
    final response = await ApiClient.post('/pairing', {
      'publicKey': myPublicKey,
    });
    
    final data = jsonDecode(response.body);
    String pairingId = data['id'];
    
    print("Pairing cree avec id: $pairingId");
    return pairingId;
  }

  // complete un pairing existant (scan d'un QR code)
  static Future<Map<String, dynamic>?> completePairing(String pairingId) async {
    print("Completion du pairing $pairingId...");
    
    String myPublicKey = await KeyStorage.getMyPublicKeyPem();
    
    try {
      final response = await ApiClient.put('/pairing/$pairingId', {
        'publicKey': myPublicKey,
      });
      
      final data = jsonDecode(response.body);
      
      // on recupere la cle publique du partenaire
      if (data['partnerPublicKey'] != null) {
        KeyStorage.setPartnerPublicKeyPem(data['partnerPublicKey']);
        print("Cle du partenaire enregistree !");
      }
      
      return data;
    } catch (e) {
      print("Erreur completion: $e");
      return null;
    }
  }

  // verifie si le pairing est complet (le partenaire a scanne)
  static Future<Map<String, dynamic>?> checkPairingStatus(String pairingId) async {
    print("Verification du pairing $pairingId...");
    
    try {
      final response = await ApiClient.get('/pairing/$pairingId/status');
      final data = jsonDecode(response.body);
      
      if (data['completed'] == true && data['partnerPublicKey'] != null) {
        // on sauvegarde la cle du partenaire
        KeyStorage.setPartnerPublicKeyPem(data['partnerPublicKey']);
        print("Pairing complet !");
      }
      
      return data;
    } catch (e) {
      print("Erreur verification: $e");
      return null;
    }
  }

  // supprime un pairing (finalisation)
  static Future<bool> deletePairing(String pairingId) async {
    print("Suppression du pairing $pairingId...");
    try {
      await ApiClient.delete('/pairing/$pairingId');
      print("Pairing supprime");
      return true;
    } catch (e) {
      print("Erreur suppression: $e");
      return false;
    }
  }
}
