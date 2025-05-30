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

  Future<dynamic> getBarangById(int idBarang) async {
    try {
      final response = await _apiService.get('$apiUrl/$idBarang');
      return response;
    } catch (error) {
      print('Error mendapatkan detail barang: $error');
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
      print('Mencoba mengambil barang untuk penitip ID: $idPenitip');

      // Gunakan endpoint penitipan barang yang tersedia
      final penitipanResponse = await _apiService.get(
        '/penitip/$idPenitip/penitipan',
      );

      if (penitipanResponse == null) {
        print('Respon penitipan null');
        return [];
      }

      // Debugging
      print('Respon penitipan: ${penitipanResponse is Map ? 'Map' : 'List'}');

      List<dynamic> penitipanList = [];

      // Cek format respons yang diterima
      if (penitipanResponse is Map && penitipanResponse.containsKey('data')) {
        print('Format respon dengan wrapper success/data');

        if (penitipanResponse['success'] == true) {
          penitipanList = penitipanResponse['data'] as List<dynamic>;
          print('Jumlah penitipan: ${penitipanList.length}');
        } else {
          print(
            'API mengembalikan success:false: ${penitipanResponse['message']}',
          );
          return [];
        }
      } else if (penitipanResponse is List) {
        print('Format respon langsung list');
        penitipanList = penitipanResponse;
      } else {
        print('Format respon tidak dikenali: $penitipanResponse');
        return [];
      }

      // Kumpulkan semua barang dari penitipan
      List<dynamic> allBarang = [];

      for (var penitipan in penitipanList) {
        if (penitipan.containsKey('barang')) {
          if (penitipan['barang'] is List) {
            allBarang.addAll(penitipan['barang']);
            print(
              'Menambahkan ${penitipan['barang'].length} barang dari penitipan ID ${penitipan['id_penitipan']}',
            );
          } else if (penitipan['barang'] != null) {
            allBarang.add(penitipan['barang']);
            print(
              'Menambahkan 1 barang dari penitipan ID ${penitipan['id_penitipan']}',
            );
          }
        }
      }

      print('Total barang ditemukan: ${allBarang.length}');
      return allBarang;
    } catch (error) {
      print('Error saat mengambil barang penitip: $error');
      throw error;
    }
  }
}
