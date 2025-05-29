import 'api_service.dart';

class TransaksiApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/transaksi';

  Future<dynamic> getTransaksiById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getTransaksiByPembeli(int idPembeli) async {
    try {
      final response = await _apiService.get('$apiUrl/pembeli/$idPembeli');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getLaporanPenjualanBulanan({int? tahun}) async {
    try {
      final currentYear = DateTime.now().year;
      final url =
          tahun != null
              ? '$apiUrl/laporan/penjualan-bulanan?tahun=$tahun'
              : '$apiUrl/laporan/penjualan-bulanan?tahun=$currentYear';

      final response = await _apiService.get(url);
      return response;
    } catch (error) {
      print("Error mengambil laporan penjualan bulanan: $error");
      throw error;
    }
  }
}
