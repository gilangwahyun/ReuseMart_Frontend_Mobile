import 'api_service.dart';

class PenitipanBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/penitipanBarang';

  Future<dynamic> getAllPenitipanBarang() async {
    try {
      print('Mengambil semua data penitipan');
      final response = await _apiService.get(apiUrl);
      print('Response get all penitipan: $response');
      return response;
    } catch (error) {
      print('Error mengambil semua data penitipan: $error');
      return [];
    }
  }

  Future<dynamic> getPenitipanBarangById(int id) async {
    try {
      print('Mengambil data penitipan dengan ID: $id');
      final response = await _apiService.get('$apiUrl/$id');
      print('Response penitipan by ID: $response');
      return response;
    } catch (error) {
      print('Error mengambil data penitipan by ID: $error');
      return null;
    }
  }

  Future<dynamic> getPenitipanBarangByIdBarang(int idBarang) async {
    try {
      print('Mengambil data penitipan untuk barang ID: $idBarang');
      final response = await _apiService.get('$apiUrl/barang/$idBarang');
      print('Response penitipan by barang: $response');

      // Jika response null atau error 404, kembalikan null
      if (response == null ||
          (response is Map &&
              response['message']?.toString().toLowerCase().contains(
                    'tidak ditemukan',
                  ) ==
                  true)) {
        print('Data penitipan tidak ditemukan untuk barang ID: $idBarang');
        return null;
      }

      // Jika response adalah Map dengan data wrapper
      if (response is Map && response.containsKey('data')) {
        return response['data'];
      }

      // Jika response langsung berupa data
      return response;
    } catch (error) {
      print('Error mengambil data penitipan by barang: $error');
      return null;
    }
  }

  Future<dynamic> getPenitipanByPenitipId(int idPenitip) async {
    try {
      print('Mengambil data penitipan untuk penitip ID: $idPenitip');
      final response = await _apiService.get('penitip/$idPenitip/penitipan');
      print('Response penitipan by penitip: $response');
      if (response != null) {
        return response;
      }
      return [];
    } catch (error) {
      print('Error mengambil data penitipan by penitip: $error');
      return [];
    }
  }

  Future<dynamic> createPenitipanBarang(Map<String, dynamic> data) async {
    try {
      print('Membuat penitipan baru dengan data: $data');
      final response = await _apiService.post(apiUrl, data);
      print('Response create penitipan: $response');
      return response;
    } catch (error) {
      print('Error membuat penitipan: $error');
      throw error;
    }
  }

  Future<dynamic> updatePenitipanBarang(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      print('Update penitipan ID $id dengan data: $data');
      final response = await _apiService.put('$apiUrl/$id', data);
      print('Response update penitipan: $response');
      return response;
    } catch (error) {
      print('Error update penitipan: $error');
      throw error;
    }
  }

  Future<dynamic> deletePenitipanBarang(int id) async {
    try {
      print('Menghapus penitipan ID: $id');
      final response = await _apiService.delete('$apiUrl/$id');
      print('Response delete penitipan: $response');
      return response;
    } catch (error) {
      print('Error menghapus penitipan: $error');
      throw error;
    }
  }
}
