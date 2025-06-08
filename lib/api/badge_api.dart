import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/local_storage.dart';
import '../config/api_config.dart';

class BadgeApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>?> getTopSeller() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('$baseUrl/api/badge/get-top-seller'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        // Tidak ada TOP SELLER yang aktif
        return null;
      } else {
        throw Exception('Gagal mengambil data TOP SELLER');
      }
    } catch (e) {
      print('Error in getTopSeller: $e');
      return null;
    }
  }
}
