import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class ApiClient {
  static const String baseUrl = 'https://alto.samyn.ovh';

  /// Requête GET
  static Future<http.Response> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      return response;
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  /// Requête POST
  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      return response;
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  /// Requête PUT
  static Future<http.Response> put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      return response;
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  /// Requête DELETE
  static Future<http.Response> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      return response;
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  /// Vérifie si la réponse est valide
  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException('Erreur serveur', response.statusCode);
    }
  }
}