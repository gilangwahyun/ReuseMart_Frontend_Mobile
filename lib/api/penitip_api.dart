import 'api_service.dart';

class PenitipApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/penitip';

  Future<dynamic> registerPenitip(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      throw error;
    }
  }

  // Tampilkan semua penitip
  Future<dynamic> getAllPenitip() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  // Tampilkan penitip berdasarkan ID
  Future<dynamic> getPenitipById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  // Tampilkan penitip berdasarkan ID user
  Future<dynamic> getPenitipByUserId(int idUser) async {
    try {
      final response = await _apiService.get('$apiUrl/user/$idUser');
      return response;
    } catch (error) {
      print('Error saat mendapatkan penitip by user ID $idUser: $error');
      throw error;
    }
  }

  // Update penitip
  Future<dynamic> updatePenitip(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('$apiUrl/$id', data);
      return response;
    } catch (error) {
      print('Error saat update penitip ID $id: $error');
      throw error;
    }
  }

  // Hapus penitip
  Future<dynamic> deletePenitip(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      print('Error saat hapus penitip ID $id: $error');
      throw error;
    }
  }

  Future<dynamic> searchPenitipByName(String namaPenitip) async {
    try {
      // Coba endpoint pencarian spesifik
      final response = await _apiService.get(
        '$apiUrl/search?nama_penitip=${Uri.encodeComponent(namaPenitip)}',
      );
      return response;
    } catch (error) {
      print('Search error: $error');
      // Jika gagal, coba pendekatan alternatif
      try {
        final allPenitip = await getAllPenitip();
        // Implementasikan filter sisi klien sebagai fallback
        if (allPenitip is List) {
          return allPenitip
              .where(
                (penitip) =>
                    penitip['nama_penitip'] != null &&
                    penitip['nama_penitip'].toLowerCase().contains(
                      namaPenitip.toLowerCase(),
                    ),
              )
              .toList();
        }
        return [];
      } catch (secondError) {
        print('Fallback search error: $secondError');
        throw secondError;
      }
    }
  }

  Future<dynamic> getRated(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/avg-rate/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> publicShow(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/public-show/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
