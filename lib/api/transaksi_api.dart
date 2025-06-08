import 'api_service.dart';

class TransaksiApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/transaksi';

  Future<dynamic> getAllTransaksi() async {
    try {
      print('Mengambil semua transaksi');
      final response = await _apiService.get(apiUrl);
      print('Response get all transaksi: $response');
      return response;
    } catch (error) {
      print('Error mengambil semua transaksi: $error');
      return [];
    }
  }

  Future<dynamic> getTransaksiById(int id) async {
    try {
      print('Mengambil transaksi ID: $id');
      final response = await _apiService.get('$apiUrl/$id');
      print('Response get transaksi by ID: $response');
      return response;
    } catch (error) {
      print('Error mengambil transaksi by ID: $error');
      return null;
    }
  }

  Future<dynamic> getTransaksiByPembeli(int idPembeli) async {
    try {
      print('Mengambil transaksi pembeli ID: $idPembeli');
      final response = await _apiService.get('$apiUrl/pembeli/$idPembeli');
      print('Response get transaksi by pembeli: $response');

      // Response akan selalu berupa List karena sudah ditangani di ApiService
      if (response is List) {
        print('Raw response type: List<dynamic>');
        print('Raw response: $response');
        print('Processing list response with ${response.length} items');
        return response;
      }

      print('Unexpected response type: ${response.runtimeType}');
      return [];
    } catch (error) {
      print('Error mengambil transaksi by pembeli: $error');
      return [];
    }
  }

  Future<dynamic> createTransaksi(Map<String, dynamic> data) async {
    try {
      print('Membuat transaksi baru: $data');
      final response = await _apiService.post(apiUrl, data);
      print('Response create transaksi: $response');
      return response;
    } catch (error) {
      print('Error membuat transaksi: $error');
      throw error;
    }
  }

  Future<dynamic> updateTransaksi(int id, Map<String, dynamic> data) async {
    try {
      print('Update transaksi ID $id: $data');
      final response = await _apiService.put('$apiUrl/$id', data);
      print('Response update transaksi: $response');
      return response;
    } catch (error) {
      print('Error update transaksi: $error');
      throw error;
    }
  }

  Future<dynamic> deleteTransaksi(int id) async {
    try {
      print('Menghapus transaksi ID: $id');
      final response = await _apiService.delete('$apiUrl/$id');
      print('Response delete transaksi: $response');
      return response;
    } catch (error) {
      print('Error menghapus transaksi: $error');
      throw error;
    }
  }

  Future<dynamic> getLaporanPenjualanBulanan({int? tahun}) async {
    try {
      print('Mengambil laporan penjualan bulanan');
      final currentYear = DateTime.now().year;
      final url =
          tahun != null
              ? '$apiUrl/laporan/penjualan-bulanan?tahun=$tahun'
              : '$apiUrl/laporan/penjualan-bulanan?tahun=$currentYear';

      final response = await _apiService.get(url);
      print('Response laporan penjualan: $response');
      return response;
    } catch (error) {
      print('Error mengambil laporan penjualan: $error');
      return null;
    }
  }
}
