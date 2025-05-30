import 'api_service.dart';

class PenitipanBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/penitipanBarang';

  Future<dynamic> getAllPenitipanBarang() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getPenitipanBarangById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getPenitipanBarangByIdBarang(int idBarang) async {
    try {
      final response = await _apiService.get('$apiUrl/barang/$idBarang');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getPenitipanBarangByIdPenitip(int idPenitip) async {
    try {
      final response = await _apiService.get('/penitip/$idPenitip/penitipan');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> createPenitipanBarang(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> updatePenitipanBarang(
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

  Future<dynamic> deletePenitipanBarang(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
