import 'api_service.dart';
import 'dart:developer' as developer;

class KategoriBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/kategoriBarang';

  Future<dynamic> getAllKategori() async {
    try {
      developer.log('Mengambil semua kategori barang');
      final response = await _apiService.get(apiUrl);

      // Log untuk debugging
      developer.log('Response kategori: $response');

      // Periksa format response
      if (response is List) {
        // Jika response langsung berupa array
        return response;
      } else if (response is Map && response.containsKey('data')) {
        // Jika response berupa objek dengan properti 'data'
        return response['data'];
      } else {
        // Format lainnya, kembalikan apa adanya
        return response;
      }
    } catch (error) {
      developer.log('Error mengambil kategori: $error');
      throw error;
    }
  }

  Future<dynamic> getKategoriById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
