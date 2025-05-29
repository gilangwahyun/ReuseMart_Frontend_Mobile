import 'api_service.dart';

class KategoriBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/kategoriBarang';

  Future<dynamic> getAllKategori() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
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
