import 'api_service.dart';
import '../models/foto_barang_model.dart';

class FotoBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = 'fotoBarang';

  // Mendapatkan semua foto barang berdasarkan ID barang
  Future<List<FotoBarangModel>> getFotoByBarangId(int idBarang) async {
    try {
      print('Mengambil foto untuk barang ID: $idBarang');
      final response = await _apiService.get('$apiUrl/$idBarang');

      if (response == null) {
        print('Response null dari API foto barang');
        return [];
      }

      // Debug respons
      print('Tipe respons: ${response.runtimeType}');
      print('Response raw: $response');

      if (response is Map) {
        print('Kunci dalam respons: ${response.keys.toList()}');
      }

      // Cek format response sesuai struktur dari backend
      if (response is Map &&
          response.containsKey('data') &&
          response['success'] == true) {
        final dataList = response['data'] as List;
        print('Jumlah foto ditemukan: ${dataList.length}');

        // Debug setiap item foto
        for (var item in dataList) {
          print('Data foto: $item');
        }

        return dataList
            .map((item) {
              try {
                return FotoBarangModel.fromJson(item);
              } catch (e) {
                print('Error parsing foto item: $e');
                return null;
              }
            })
            .whereType<FotoBarangModel>()
            .toList();
      } else if (response is List) {
        print('Jumlah foto ditemukan (format list): ${response.length}');
        return response
            .map((item) {
              try {
                return FotoBarangModel.fromJson(item);
              } catch (e) {
                print('Error parsing foto item: $e');
                return null;
              }
            })
            .whereType<FotoBarangModel>()
            .toList();
      } else if (response is Map && response.containsKey('message')) {
        print('API Message: ${response['message']}');
        return [];
      }

      print('Format respons tidak dikenali. Mengembalikan list kosong');
      return [];
    } catch (e) {
      print('Error mengambil foto barang untuk ID $idBarang: $e');
      return [];
    }
  }

  Future<FotoBarangModel?> getThumbnailFoto(int idBarang) async {
    try {
      final List<FotoBarangModel> fotos = await getFotoByBarangId(idBarang);

      if (fotos.isEmpty) {
        print('Tidak ada foto untuk barang ID: $idBarang');
        return null;
      }

      // Cari foto dengan is_thumbnail = true
      final thumbnail = fotos.firstWhere(
        (foto) => foto.isThumbnail == true,
        orElse: () => fotos.first, // Jika tidak ada, gunakan foto pertama
      );

      return thumbnail;
    } catch (error) {
      print("Error mengambil thumbnail foto: $error");
      return null;
    }
  }
}
