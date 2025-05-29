import 'api_service.dart';

class AlamatApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/alamat';

  Future<dynamic> createAlamat(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getAlamat() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> updateAlamat(int id, Map<String, dynamic> alamatData) async {
    try {
      final response = await _apiService.put('$apiUrl/$id', alamatData);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getAlamatById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getAlamatByPembeliId(int idPembeli) async {
    try {
      final response = await _apiService.get('$apiUrl/pembeli/$idPembeli');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> deleteAlamat(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
