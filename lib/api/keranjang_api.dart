import 'api_service.dart';

class KeranjangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/keranjang';

  Future<dynamic> getAllKeranjang() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getKeranjangById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getKeranjangByIdUser(int idUser) async {
    try {
      final response = await _apiService.get('$apiUrl/user/$idUser');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getKeranjangByPembeli(int idPembeli) async {
    try {
      final response = await _apiService.get('$apiUrl/pembeli/$idPembeli');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> createKeranjang(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> deleteKeranjang(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
