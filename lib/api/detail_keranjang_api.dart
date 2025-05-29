import 'api_service.dart';

class DetailKeranjangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/detailKeranjang';

  Future<dynamic> getAllDetailKeranjang() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getDetailKeranjangById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getDetailKeranjangByKeranjang(int idKeranjang) async {
    try {
      final response = await _apiService.get('$apiUrl/keranjang/$idKeranjang');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> createDetailKeranjang(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> updateDetailKeranjang(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('$apiUrl/$id', data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> deleteDetailKeranjang(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
