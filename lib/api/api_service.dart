import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

// URL API untuk mengakses Laravel
// const String BASE_URL = "http://10.0.2.2:8000";
const String BASE_URL = "http://10.53.5.132:8000";

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String get baseUrl => '$BASE_URL/api';

  // Fungsi helper untuk log error
  void logError(String prefix, dynamic error) {
    developer.log('$prefix: $error');
    if (error is http.Response) {
      developer.log('Status: ${error.statusCode}');
      developer.log('Data: ${error.body}');
      developer.log('Headers: ${error.headers}');
    } else if (error is Exception) {
      developer.log('Error in setup: ${error.toString()}');
    }
  }

  // Menambahkan token ke setiap request
  Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        developer.log(
          'Token ditambahkan: ${token.substring(0, math.min(token.length, 10))}...',
        );
      }
    } catch (error) {
      developer.log('Error mengambil token: $error');
    }

    return headers;
  }

  // Memastikan endpoint selalu memiliki format yang benar (tanpa leading slash)
  String _formatEndpoint(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    // Log the formatted endpoint for debugging
    developer.log('Formatted endpoint: $endpoint');

    return endpoint;
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final formattedEndpoint = _formatEndpoint(endpoint);
      var uri = Uri.parse('$baseUrl/${formattedEndpoint}');

      // Add query parameters if provided
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      developer.log('GET Request URL: $uri');

      final headers = await _getHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      developer.log('Response GET $endpoint: ${response.statusCode}');
      developer.log('Response body: ${response.body.substring(0, math.min(response.body.length, 200))}...');
      return _handleResponse(response);
    } catch (error) {
      logError('Error pada GET request', error);
      throw _createCustomError(error);
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final formattedEndpoint = _formatEndpoint(endpoint);
      final url = '$baseUrl/${formattedEndpoint}';
      developer.log('POST Request URL: $url');
      developer.log('POST Request data: ${json.encode(data)}');

      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: 15));

      developer.log('Response POST $endpoint: ${response.statusCode}');
      developer.log('Response body: ${response.body.substring(0, math.min(response.body.length, 200))}...');
      return _handleResponse(response);
    } catch (error) {
      logError('Error pada POST request', error);
      throw _createCustomError(error);
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final formattedEndpoint = _formatEndpoint(endpoint);
      final url = '$baseUrl/${formattedEndpoint}';
      developer.log('PUT Request URL: $url');

      final headers = await _getHeaders();
      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: 10));

      developer.log('Response PUT $endpoint: ${response.statusCode}');
      return _handleResponse(response);
    } catch (error) {
      logError('Error pada PUT request', error);
      throw _createCustomError(error);
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final formattedEndpoint = _formatEndpoint(endpoint);
      final url = '$baseUrl/${formattedEndpoint}';
      developer.log('DELETE Request URL: $url');

      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      developer.log('Response DELETE $endpoint: ${response.statusCode}');
      return _handleResponse(response);
    } catch (error) {
      logError('Error pada DELETE request', error);
      throw _createCustomError(error);
    }
  }

  // Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        developer.log('Error decoding JSON response: $e');
        return response.body;
      }
    } else {
      throw HttpException(
        message: _parseErrorMessage(response),
        statusCode: response.statusCode,
        response: response,
      );
    }
  }

  // Parse error message dari response
  String _parseErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? 'Terjadi kesalahan saat menghubungi server.';
    } catch (e) {
      developer.log('Error parsing error message: $e');
      return 'Terjadi kesalahan saat menghubungi server. Silakan coba lagi nanti.';
    }
  }

  // Buat custom error
  Exception _createCustomError(dynamic error) {
    if (error is HttpException) {
      return error;
    }

    return Exception(
      error.toString().contains('SocketException')
          ? 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
          : error.toString().contains('timeout')
          ? 'Request timed out. Server mungkin sedang down atau tidak dapat dijangkau.'
          : 'Terjadi kesalahan saat menghubungi server. Silakan coba lagi nanti.',
    );
  }
}

// Custom HTTP Exception
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final http.Response response;

  HttpException({
    required this.message,
    required this.statusCode,
    required this.response,
  });

  @override
  String toString() => message;
}

// Helper function untuk min (karena substring memerlukan nilai min)
int min(int a, int b) {
  return a < b ? a : b;
}
