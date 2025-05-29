import 'api_service.dart';

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
      final response = await _apiService.get('$apiUrl/user/$idUser');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
