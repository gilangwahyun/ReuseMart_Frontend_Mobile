import 'api_service.dart';

class AlokasiDonasiApi {
  final ApiService _apiService = ApiService();

  /// Mendapatkan semua data alokasi donasi
  Future<dynamic> getAllAlokasiDonasi() async {
    try {
      final response = await _apiService.get('/alokasiDonasi');
      return response;
    } catch (error) {
      print('Error fetching alokasi donasi: $error');
      return [];
    }
  }

  /// Mendapatkan detail alokasi donasi berdasarkan ID
  Future<dynamic> getAlokasiDonasiById(int id) async {
    try {
      final response = await _apiService.get('/alokasiDonasi/$id');
      return response;
    } catch (error) {
      print('Error fetching alokasi donasi detail: $error');
      return null;
    }
  }

  /// Mendapatkan alokasi donasi berdasarkan organisasi
  Future<dynamic> getAlokasiByOrganisasi(String organisasiName) async {
    try {
      final response = await _apiService.post('/alokasiDonasi/search', {
        'organisasi': organisasiName,
      });
      return response;
    } catch (error) {
      print('Error searching alokasi donasi by organisasi: $error');
      return [];
    }
  }

  /// Mendapatkan alokasi donasi untuk barang tertentu
  Future<dynamic> getAlokasiByBarangId(int idBarang) async {
    try {
      final response = await _apiService.get('/alokasiDonasi/barang/$idBarang');
      return response;
    } catch (error) {
      print('Error fetching alokasi donasi for barang: $error');
      return null;
    }
  }
}
