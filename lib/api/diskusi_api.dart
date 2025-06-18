import 'api_service.dart';

class DiskusiApi {
  final ApiService _apiService = ApiService();

  /// Mendapatkan semua diskusi
  Future<dynamic> getAllDiskusi() async {
    try {
      final response = await _apiService.get('/diskusi');
      return response;
    } catch (error) {
      print('Error fetching diskusi: $error');
      return [];
    }
  }

  /// Mendapatkan detail diskusi berdasarkan ID
  Future<dynamic> getDiskusiById(int id) async {
    try {
      final response = await _apiService.get('/diskusi/$id');
      return response;
    } catch (error) {
      print('Error fetching diskusi detail: $error');
      return null;
    }
  }

  /// Mendapatkan diskusi berdasarkan ID barang
  Future<dynamic> getDiskusiByBarangId(int idBarang) async {
    try {
      final response = await _apiService.get('/diskusi/barang/$idBarang');
      return response;
    } catch (error) {
      print('Error fetching diskusi for barang: $error');
      return [];
    }
  }

  /// Menambahkan diskusi baru
  Future<dynamic> addDiskusi(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/diskusi', data);
      return response;
    } catch (error) {
      print('Error adding diskusi: $error');
      throw error;
    }
  }

  /// Mengupdate diskusi
  Future<dynamic> updateDiskusi(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/diskusi/$id', data);
      return response;
    } catch (error) {
      print('Error updating diskusi: $error');
      throw error;
    }
  }

  /// Menghapus diskusi
  Future<dynamic> deleteDiskusi(int id) async {
    try {
      final response = await _apiService.delete('/diskusi/$id');
      return response;
    } catch (error) {
      print('Error deleting diskusi: $error');
      throw error;
    }
  }
}
