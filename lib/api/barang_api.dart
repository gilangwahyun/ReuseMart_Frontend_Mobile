import 'api_service.dart';

class BarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/barang';

  Future<dynamic> getAllBarang() async {
    try {
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getAllActiveBarang() async {
    try {
      final response = await _apiService.get(
        '$apiUrl/cari-status?status=Aktif',
      );
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getAllDonateBarang() async {
    try {
      final response = await _apiService.get(
        '$apiUrl/cari-status?status=Barang untuk Donasi',
      );
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getBarangById(int id) async {
    try {
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> createBarang(Map<String, dynamic> barangData) async {
    try {
      final response = await _apiService.post(apiUrl, barangData);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> updateBarang(int id, Map<String, dynamic> barangData) async {
    try {
      final response = await _apiService.put('$apiUrl/$id', barangData);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> deleteBarang(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getBarangByKategori(String namaKategori) async {
    try {
      final response = await _apiService.get(
        '$apiUrl/cari-kategori?kategori=${Uri.encodeComponent(namaKategori)}',
      );
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> searchBarangByName(String namaBarang) async {
    try {
      print("Mencari barang dengan kata kunci: $namaBarang");
      final response = await _apiService.get(
        '$apiUrl/cari?nama_barang=$namaBarang',
      );
      return response;
    } catch (error) {
      print("Terjadi kesalahan saat mencari barang: $error");
      throw error;
    }
  }

  Future<dynamic> updateBarangRating(
    int id,
    Map<String, dynamic> barangData,
  ) async {
    try {
      final response = await _apiService.put('$apiUrl/$id/rating', barangData);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> searchBarangAllField({
    String? keyword,
    String? tanggalAwal,
    String? tanggalAkhir,
  }) async {
    try {
      String url = '$apiUrl/advanced/all-search?';

      if (keyword != null) url += 'keyword=$keyword&';
      if (tanggalAwal != null) url += 'tanggal_awal=$tanggalAwal&';
      if (tanggalAkhir != null) url += 'tanggal_akhir=$tanggalAkhir&';

      // Hapus '&' terakhir jika ada
      url = url.endsWith('&') ? url.substring(0, url.length - 1) : url;

      final response = await _apiService.get(url);
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<dynamic> getLaporanStokGudang() async {
    try {
      final response = await _apiService.get('$apiUrl/laporan/stok-gudang');
      return response;
    } catch (error) {
      print("Error mengambil laporan stok gudang: $error");
      throw error;
    }
  }

  Future<dynamic> getBarangByPenitip(int idPenitip) async {
    try {
      final response = await _apiService.get('$apiUrl/penitip/$idPenitip');
      return response;
    } catch (error) {
      throw error;
    }
  }
}
