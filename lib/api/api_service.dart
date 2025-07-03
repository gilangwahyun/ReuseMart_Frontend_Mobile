import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../utils/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// URL API untuk mengakses Laravel - Dibuat public agar dapat diakses di file lain
// const String BASE_URL = "http://10.0.2.2:8000"; // Emulator
// const String BASE_URL = "http://192.168.74.230:8000";
const String BASE_URL = "https://api.reusemartuajy.my.id"; // Wifi Kos
// const String BASE_URL = "http://192.168.149.30:8000"; // Hotspot HP

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static bool _debugMode = true;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String get baseUrl => '$BASE_URL/api';

  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  void _log(String message) {
    if (_debugMode) {
      developer.log('[ApiService] $message');
    }
  }

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
        _log('Token added to headers');
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

  // Helper untuk membuat URL gambar lengkap
  String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;

    // Log untuk debug URL
    developer.log('Getting image URL for path: $imagePath');

    // Untuk gambar yang disimpan di folder public/images/barang
    if (imagePath.contains('images/barang')) {
      developer.log('Detected images/barang path, using direct URL');
      return '$BASE_URL/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';
    }

    // Untuk gambar yang disimpan di storage Laravel
    return '$BASE_URL/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/${_formatEndpoint(endpoint)}');

      _log('\n=== GET Request Details ===');
      _log('URL: $url');
      _log('Token: $token');
      _log('Timeout: ${timeout.inSeconds} seconds');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      _log('Request headers: $headers');

      final response = await http
          .get(url, headers: headers)
          .timeout(
            timeout,
            onTimeout: () {
              _log('Request timed out after ${timeout.inSeconds} seconds');
              throw TimeoutException('Request timed out');
            },
          );

      _log('\n=== Response Details ===');
      _log('Status code: ${response.statusCode}');
      _log('Response headers: ${response.headers}');
      _log('Raw response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        if (response.body.isEmpty) {
          _log('Response body is empty');
          return null;
        }

        try {
          final decodedResponse = json.decode(response.body);
          _log('Decoded response type: ${decodedResponse.runtimeType}');
          _log('Decoded response: $decodedResponse');
          return decodedResponse;
        } catch (e, stackTrace) {
          _log('Error decoding response: $e');
          _log('Stack trace: $stackTrace');
          return null;
        }
      } else if (response.statusCode == 401) {
        await LocalStorage.clearToken();
        throw Exception('Unauthorized');
      } else {
        _log('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      _log('Network error: $e');
      _log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // POST request dengan retry untuk menangani error 500
  Future<dynamic> post(String endpoint, dynamic data) async {
    // Coba pertama kali dengan timeout normal
    try {
      return await _postWithTimeout(
        endpoint,
        data,
        const Duration(seconds: 30),
      );
    } catch (e) {
      developer.log('POST request pertama gagal: $e');

      // Jika error 500, coba lagi dengan timeout lebih lama
      if (e.toString().contains('500')) {
        developer.log(
          'Mencoba ulang POST request dengan timeout lebih lama...',
        );
        try {
          return await _postWithTimeout(
            endpoint,
            data,
            const Duration(seconds: 60),
          );
        } catch (retryError) {
          developer.log('POST retry gagal: $retryError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // POST request dengan timeout kustom
  Future<dynamic> _postWithTimeout(
    String endpoint,
    dynamic data,
    Duration timeout,
  ) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/${_formatEndpoint(endpoint)}');

      _log('POST Request to: $url');
      _log('POST data: ${json.encode(data)}');
      _log('Timeout: ${timeout.inSeconds} seconds');

      final Map<String, String> headers = Map<String, String>.from(
        await _getHeaders(),
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      _log('Request headers: $headers');

      final response = await http
          .post(url, headers: headers, body: json.encode(data))
          .timeout(
            timeout,
            onTimeout: () {
              _log('POST request timed out after ${timeout.inSeconds} seconds');
              throw TimeoutException('Request timed out');
            },
          );

      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          _log('Response body is empty');
          return null;
        }
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await LocalStorage.clearToken();
        throw Exception('Unauthorized');
      } else {
        // Log error response dari server
        developer.log('ERROR RESPONSE: Status ${response.statusCode}');
        developer.log('ERROR BODY: ${response.body}');

        // Coba parse error message dari response body
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            throw Exception('Server error: ${errorData['message']}');
          }
        } catch (_) {}

        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/${_formatEndpoint(endpoint)}');

      _log('PUT Request to: $url');

      final Map<String, String> headers = Map<String, String>.from(
        await _getHeaders(),
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(data),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _log('Response body is empty');
          return null;
        }
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await LocalStorage.clearToken();
        throw Exception('Unauthorized');
      } else {
        developer.log(
          'Error response: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/${_formatEndpoint(endpoint)}');

      _log('DELETE Request to: $url');

      final Map<String, String> headers = Map<String, String>.from(
        await _getHeaders(),
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(url, headers: headers);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _log('Response body is empty');
          return null;
        }
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await LocalStorage.clearToken();
        throw Exception('Unauthorized');
      } else {
        developer.log(
          'Error response: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
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
