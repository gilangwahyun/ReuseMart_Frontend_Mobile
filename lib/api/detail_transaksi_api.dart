import 'api_service.dart';

class DetailTransaksiApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/detailTransaksi';

  /// Mendapatkan semua detail transaksi
  Future<dynamic> getAllDetailTransaksi() async {
    try {
      print('Mengambil semua data detail transaksi');
      final response = await _apiService.get(apiUrl);
      print('Response get all detail transaksi: $response');
      return response;
    } catch (error) {
      print('Error mengambil semua data detail transaksi: $error');
      return [];
    }
  }

  /// Mendapatkan detail transaksi berdasarkan ID
  Future<dynamic> getDetailTransaksiById(int id) async {
    try {
      print('Mengambil data detail transaksi dengan ID: $id');
      final response = await _apiService.get('$apiUrl/$id');
      print('Response detail transaksi by ID: $response');
      return response;
    } catch (error) {
      print('Error mengambil data detail transaksi by ID: $error');
      return null;
    }
  }

  /// Mendapatkan detail transaksi berdasarkan ID transaksi
  Future<dynamic> getDetailTransaksiByTransaksi(int idTransaksi) async {
    try {
      print('=== DEBUG: Detail Transaksi API ===');
      print('Loading details for transaction ID: $idTransaksi');
      final response = await _apiService.get(
        'detailTransaksi/transaksi/$idTransaksi',
      );
      print('Raw response: $response');
      print('Response type: ${response?.runtimeType}');

      if (response == null) {
        print('Response is null');
        return [];
      }

      // Handle response in new format (with success, message, data)
      if (response is Map<String, dynamic>) {
        print('Response is Map format');
        if (response['success'] == true) {
          final List<dynamic> detailList = response['data'] ?? [];
          print('Success: true, found ${detailList.length} details');
          return detailList;
        } else {
          print('Success: false, message: ${response['message']}');
          return [];
        }
      }

      // Handle response in direct array format
      if (response is List) {
        print('Response is direct List format');
        print('Found ${response.length} details');
        return response;
      }

      print('Unexpected response type: ${response.runtimeType}');
      return [];
    } catch (error) {
      print('Error in getDetailTransaksiByTransaksi: $error');
      return [];
    }
  }

  /// Mendapatkan detail transaksi untuk barang tertentu
  Future<dynamic> getDetailTransaksiByBarang(int idBarang) async {
    try {
      print('Mengambil data detail transaksi untuk barang ID: $idBarang');
      final response = await _apiService.get('$apiUrl/barang/$idBarang');
      print('Response detail transaksi by barang: $response');

      // Jika response null atau error 404, kembalikan null
      if (response == null ||
          (response is Map &&
              response['message']?.toString().toLowerCase().contains(
                    'tidak ditemukan',
                  ) ==
                  true)) {
        print(
          'Data detail transaksi tidak ditemukan untuk barang ID: $idBarang',
        );
        return null;
      }

      // Jika response adalah Map dengan data wrapper
      if (response is Map && response.containsKey('data')) {
        return response['data'];
      }

      // Jika response langsung berupa data
      return response;
    } catch (error) {
      print('Error mengambil data detail transaksi by barang: $error');
      return null;
    }
  }

  Future<dynamic> createDetailTransaksi(Map<String, dynamic> data) async {
    try {
      print('Membuat detail transaksi baru: $data');
      final response = await _apiService.post(apiUrl, data);
      print('Response create detail transaksi: $response');
      return response;
    } catch (error) {
      print('Error membuat detail transaksi: $error');
      throw error;
    }
  }

  Future<dynamic> updateDetailTransaksi(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      print('Update detail transaksi ID $id: $data');
      final response = await _apiService.put('$apiUrl/$id', data);
      print('Response update detail transaksi: $response');
      return response;
    } catch (error) {
      print('Error update detail transaksi: $error');
      throw error;
    }
  }

  Future<dynamic> deleteDetailTransaksi(int id) async {
    try {
      print('Menghapus detail transaksi ID: $id');
      final response = await _apiService.delete('$apiUrl/$id');
      print('Response delete detail transaksi: $response');
      return response;
    } catch (error) {
      print('Error menghapus detail transaksi: $error');
      throw error;
    }
  }
}
