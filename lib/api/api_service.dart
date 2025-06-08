import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../utils/local_storage.dart';

// URL API untuk mengakses Laravel - Dibuat public agar dapat diakses di file lain
const String BASE_URL = "http://10.0.2.2:8000";
// const String BASE_URL = "http://192.168.1.4:8000";

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static bool _debugMode = false;

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
    if (endpoint.startsWith('/')) {
      return endpoint.substring(1);
    }
    return endpoint;
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/$endpoint');

      _log('GET Request to: $url');

      final Map<String, String> headers = Map<String, String>.from(
        await _getHeaders(),
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      _log('Request headers prepared');

      final response = await http.get(url, headers: headers);

      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _log('Response body is empty, returning empty array');
          return [];
        }

        try {
          final decodedResponse = json.decode(response.body);
          _log('Decoded response: $decodedResponse');

          // Jika response adalah Map dengan format success dan data
          if (decodedResponse is Map && decodedResponse.containsKey('data')) {
            _log('Response contains data field');
            return decodedResponse['data'];
          }

          return decodedResponse;
        } catch (e) {
          developer.log('Error decoding response: $e');
          return [];
        }
      } else if (response.statusCode == 401) {
        // Token tidak valid atau expired
        await LocalStorage.clearToken();
        throw Exception('Unauthorized');
      } else {
        developer.log(
          'Error response: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/$endpoint');

      _log('POST Request to: $url');

      final Map<String, String> headers = Map<String, String>.from(
        await _getHeaders(),
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      _log('Response status: ${response.statusCode}');

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

  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse('$baseUrl/$endpoint');

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
      final url = Uri.parse('$baseUrl/$endpoint');

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
