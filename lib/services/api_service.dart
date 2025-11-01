import 'dart:convert';
import 'dart:io'; // ADD THIS: for SocketException
import 'package:http/http.dart' as http;
import 'token_service.dart';
import '../config/api_config.dart'; // Fixed path

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _tokenService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // Success with no content
      } else {
        throw ApiException('Request failed with status code ${response.statusCode}');
      }
    }
    final dynamic body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(body['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Could not connect to the server. Please check your network connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {required Map<String, dynamic> body}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: await _getHeaders(),
        body: jsonEncode(body), // Always send JSON
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Could not connect to the server. Please check your network connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {required Map<String, dynamic> body}) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Could not connect to the server. Please check your network connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Could not connect to the server. Please check your network connection.');
    } catch (e) {
      rethrow;
    }
  }
}
