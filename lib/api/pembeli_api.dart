import 'api_service.dart';
import 'dart:convert';

class PembeliApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/pembeli';

  Future<dynamic> createPembeli(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(apiUrl, userData);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getPembeli(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getPembeliByUserId(int idUser) async {
    try {
      print('Mencoba mendapatkan data pembeli untuk user ID: $idUser');
      final response = await _apiService.get('$apiUrl/user/$idUser');
      print(
        'Response dari API pembeli/user/$idUser: ${response != null ? 'ditemukan' : 'null'}',
      );

      // Format response agar konsisten dengan PenitipApi
      if (response != null) {
        // Cek jika response sudah dalam format yang diharapkan
        if (response is Map && response.containsKey('success')) {
          return response;
        }

        // Jika response langsung berupa objek pembeli, format ulang ke format yang konsisten
        return {
          'success': true,
          'message': 'Data pembeli berhasil ditemukan',
          'data': response,
        };
      }

      return response;
    } catch (error) {
      print('Error saat mendapatkan pembeli by user ID: $error');
      throw error;
    }
  }
}
