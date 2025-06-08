import 'api_service.dart';
import 'dart:developer' as developer;

class BarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/barang';

  Future<dynamic> getAllBarang() async {
    try {
      developer.log('Mengambil semua data barang');
      final response = await _apiService.get(apiUrl);
      return response;
    } catch (error) {
      developer.log('Error mengambil semua data barang: $error');
      return [];
    }
  }

  Future<dynamic> getAllActiveBarang() async {
    try {
      developer.log('Mengambil semua barang aktif');
      final response = await _apiService.get(
        '$apiUrl/cari-status?status=Aktif',
      );
      return response;
    } catch (error) {
      developer.log('Error mengambil barang aktif: $error');
      return [];
    }
  }

  Future<dynamic> getAllDonateBarang() async {
    try {
      developer.log('Mengambil semua barang untuk donasi');
      final response = await _apiService.get(
        '$apiUrl/cari-status?status=Barang untuk Donasi',
      );
      return response;
    } catch (error) {
      developer.log('Error mengambil barang donasi: $error');
      return [];
    }
  }

  Future<dynamic> getBarangById(int id) async {
    try {
      developer.log('Mengambil detail barang dengan ID: $id');
      final response = await _apiService.get('$apiUrl/$id');
      developer.log('Response detail barang (raw): $response');

      if (response == null) {
        developer.log('Data barang tidak ditemukan');
        return null;
      }

      // Log struktur response
      if (response is Map) {
        developer.log('Response is Map with keys: ${response.keys.toList()}');
        if (response.containsKey('data')) {
          developer.log('Data field contains: ${response['data']}');

          // Log penitipan data jika ada
          if (response['data'] is Map &&
              response['data'].containsKey('penitipan_barang')) {
            developer.log(
              'Penitipan data found: ${response['data']['penitipan_barang']}',
            );
          }
        }
      }

      // Jika response adalah Map dengan data wrapper
      if (response is Map && response.containsKey('data')) {
        return response['data'];
      }

      // Jika response langsung berupa data
      return response;
    } catch (error, stackTrace) {
      developer.log('Error mengambil detail barang: $error');
      developer.log('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<dynamic> createBarang(Map<String, dynamic> barangData) async {
    try {
      developer.log('Membuat barang baru');
      final response = await _apiService.post(apiUrl, barangData);
      return response;
    } catch (error) {
      developer.log('Error membuat barang: $error');
      return null;
    }
  }

  Future<dynamic> updateBarang(int id, Map<String, dynamic> barangData) async {
    try {
      developer.log('Mengupdate barang ID: $id');
      final response = await _apiService.put('$apiUrl/$id', barangData);
      return response;
    } catch (error) {
      developer.log('Error mengupdate barang: $error');
      return null;
    }
  }

  Future<dynamic> deleteBarang(int id) async {
    try {
      developer.log('Menghapus barang ID: $id');
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      developer.log('Error menghapus barang: $error');
      return null;
    }
  }

  Future<dynamic> getBarangByKategori(String namaKategori) async {
    try {
      developer.log('Mencari barang dengan kategori: $namaKategori');
      final response = await _apiService.get(
        '$apiUrl/cari-kategori?kategori=$namaKategori',
      );
      return response;
    } catch (error) {
      developer.log('Error mencari barang by kategori: $error');
      return [];
    }
  }

  Future<dynamic> searchBarangByName(String? namaBarang) async {
    try {
      if (namaBarang == null || namaBarang.trim().isEmpty) {
        return await getAllActiveBarang();
      }

      developer.log('Mencari barang dengan nama: $namaBarang');
      final response = await _apiService.get(
        '$apiUrl/cari?nama_barang=$namaBarang',
      );
      return response;
    } catch (error) {
      developer.log('Error mencari barang by nama: $error');
      return [];
    }
  }

  Future<dynamic> updateBarangRating(
    int id,
    Map<String, dynamic> ratingData,
  ) async {
    try {
      developer.log('Mengupdate rating barang ID: $id');
      final response = await _apiService.put('$apiUrl/$id/rating', ratingData);
      return response;
    } catch (error) {
      developer.log('Error mengupdate rating: $error');
      return null;
    }
  }

  Future<dynamic> searchBarangAllField({
    String? keyword,
    String? tanggalAwal,
    String? tanggalAkhir,
  }) async {
    try {
      developer.log('Mencari barang dengan multiple field');

      String endpoint = '$apiUrl/advanced/all-search';
      List<String> params = [];

      if (keyword != null) params.add('keyword=$keyword');
      if (tanggalAwal != null) params.add('tanggal_awal=$tanggalAwal');
      if (tanggalAkhir != null) params.add('tanggal_akhir=$tanggalAkhir');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint);
      return response;
    } catch (error) {
      developer.log('Error mencari barang all field: $error');
      return [];
    }
  }

  Future<dynamic> getLaporanStokGudang() async {
    try {
      developer.log('Mengambil laporan stok gudang');
      final response = await _apiService.get('$apiUrl/laporan/stok-gudang');
      return response;
    } catch (error) {
      developer.log('Error mengambil laporan stok: $error');
      return null;
    }
  }

  Future<dynamic> getBarangByPenitip(int idPenitip) async {
    try {
      print('=== DEBUG: getBarangByPenitip ===');
      print('Mengambil barang penitip ID: $idPenitip');
      final response = await _apiService.get('penitip/$idPenitip/penitipan');
      print('Raw Response: $response');

      if (response == null) return [];

      List<dynamic> penitipanList = [];
      if (response is Map && response.containsKey('data')) {
        print('Response is Map with data field');
        if (response['success'] == true) {
          print('Success is true, extracting data list');
          penitipanList = response['data'] as List<dynamic>;
        }
      } else if (response is List) {
        print('Response is direct List');
        penitipanList = response;
      }

      print('=== DEBUG: Processing Penitipan List ===');
      print('Found ${penitipanList.length} penitipan records');

      List<dynamic> allBarang = [];
      for (var penitipan in penitipanList) {
        if (penitipan is Map && penitipan.containsKey('barang')) {
          var barangList = penitipan['barang'];
          if (barangList is List) {
            for (var barang in barangList) {
              if (barang is Map) {
                // Log barang basic info
                print('\n=== Barang Info ===');
                print('ID: ${barang['id_barang']}');
                print('Nama: ${barang['nama_barang']}');
                print('Status: ${barang['status_barang']}');

                // Add penitipan data
                barang['penitipan_barang'] = {
                  'id_penitipan': penitipan['id_penitipan'],
                  'id_penitip': penitipan['id_penitip'],
                  'tanggal_awal_penitipan': penitipan['tanggal_awal_penitipan'],
                  'tanggal_akhir_penitipan':
                      penitipan['tanggal_akhir_penitipan'],
                  'nama_petugas_qc': penitipan['nama_petugas_qc'],
                  'id_pegawai': penitipan['id_pegawai'],
                  'penitip': penitipan['penitip'],
                  'pegawai': penitipan['pegawai'],
                };

                // Check and log detail transaksi
                if (barang.containsKey('detail_transaksi')) {
                  print('\n=== Detail Transaksi Info ===');
                  var detailTransaksi = barang['detail_transaksi'];
                  print('Detail Transaksi Raw: $detailTransaksi');

                  if (detailTransaksi != null && detailTransaksi is Map) {
                    print(
                      'ID Detail Transaksi: ${detailTransaksi['id_detail_transaksi']}',
                    );
                    print('Harga Item: ${detailTransaksi['harga_item']}');

                    // Check and log transaksi
                    if (detailTransaksi.containsKey('transaksi')) {
                      print('\n=== Transaksi Info ===');
                      var transaksi = detailTransaksi['transaksi'];
                      print('Transaksi Raw: $transaksi');

                      if (transaksi != null && transaksi is Map) {
                        print('ID Transaksi: ${transaksi['id_transaksi']}');
                        print('Status: ${transaksi['status_transaksi']}');
                        print('Tanggal: ${transaksi['tanggal_transaksi']}');
                      }
                    }
                  }
                }
              }
            }
            allBarang.addAll(barangList);
          } else if (barangList != null) {
            allBarang.add(barangList);
          }
        }
      }

      print('\n=== DEBUG: Final Result ===');
      print('Total barang ditemukan: ${allBarang.length}');
      if (allBarang.isNotEmpty) {
        var firstItem = allBarang.first;
        print('Sample data structure:');
        print('Available keys: ${firstItem.keys.toList()}');
        if (firstItem.containsKey('detail_transaksi')) {
          print('Has detail_transaksi: Yes');
          print('Detail transaksi structure: ${firstItem['detail_transaksi']}');
        } else {
          print('Has detail_transaksi: No');
        }
      }

      return allBarang;
    } catch (error, stackTrace) {
      print('Error mengambil barang penitip: $error');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
