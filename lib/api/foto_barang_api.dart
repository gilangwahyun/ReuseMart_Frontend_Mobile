import 'api_service.dart';
import '../models/foto_barang_model.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // Tambahkan import untuk json encoder

class FotoBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = 'fotoBarang';

  // Mendapatkan semua foto barang berdasarkan ID barang
  Future<List<FotoBarangModel>> getFotoByBarangId(int idBarang) async {
    try {
      developer.log('\n=== DEBUG: getFotoByBarangId ===');
      developer.log('Mengambil foto untuk barang ID: $idBarang');
      developer.log('URL yang digunakan: $apiUrl/$idBarang');

      final response = await _apiService.get('$apiUrl/$idBarang');

      // Pretty print response untuk debugging
      final JsonEncoder encoder = JsonEncoder.withIndent('  ');
      developer.log('\n=== DEBUG: Raw API Response ===');
      developer.log('Response Type: ${response.runtimeType}');
      developer.log('Response Content:');
      developer.log(encoder.convert(response));

      if (response == null) {
        developer.log('Response null dari API foto barang');
        return [];
      }

      // Debug response structure
      if (response is Map<String, dynamic>) {
        developer.log('\n=== DEBUG: Response Structure ===');
        developer.log('Keys available: ${response.keys.toList()}');
        developer.log('Has success key: ${response.containsKey('success')}');
        developer.log('Success value: ${response['success']}');
        developer.log('Has data key: ${response.containsKey('data')}');
        if (response.containsKey('data')) {
          developer.log('Data type: ${response['data'].runtimeType}');
          developer.log('Raw data content:');
          developer.log(encoder.convert(response['data']));
        }
      }

      // Coba format response yang sama dengan web
      if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['success'] == true) {
        developer.log('\n=== DEBUG: Processing Web Format Response ===');
        final dataList = response['data'] as List;
        developer.log('Jumlah foto ditemukan: ${dataList.length}');

        for (var item in dataList) {
          developer.log('\nFoto item details:');
          developer.log(encoder.convert(item));
        }

        final fotoList =
            dataList
                .map((item) {
                  developer.log('\nProcessing foto item:');
                  developer.log('Raw item: ${encoder.convert(item)}');
                  try {
                    final foto = FotoBarangModel.fromJson(item);
                    developer.log('Berhasil parse foto:');
                    developer.log('- ID: ${foto.idFotoBarang}');
                    developer.log('- URL: ${foto.urlFoto}');
                    developer.log('- Is Thumbnail: ${foto.isThumbnail}');
                    return foto;
                  } catch (e, stackTrace) {
                    developer.log('Error parsing foto item: $e');
                    developer.log('Stack trace: $stackTrace');
                    return null;
                  }
                })
                .whereType<FotoBarangModel>()
                .toList();

        developer.log('\nBerhasil parse ${fotoList.length} foto');
        return fotoList;
      }

      // Jika format tidak sesuai, coba parse langsung sebagai list
      if (response is List) {
        developer.log('\n=== DEBUG: Processing Direct List Response ===');
        developer.log('Raw list content:');
        developer.log(encoder.convert(response));

        final fotoList =
            response
                .map((item) {
                  developer.log('\nProcessing foto item from direct list:');
                  developer.log('Raw item: ${encoder.convert(item)}');
                  try {
                    final foto = FotoBarangModel.fromJson(item);
                    developer.log('Berhasil parse foto:');
                    developer.log('- ID: ${foto.idFotoBarang}');
                    developer.log('- URL: ${foto.urlFoto}');
                    developer.log('- Is Thumbnail: ${foto.isThumbnail}');
                    return foto;
                  } catch (e, stackTrace) {
                    developer.log(
                      'Error parsing foto item from direct list: $e',
                    );
                    developer.log('Stack trace: $stackTrace');
                    return null;
                  }
                })
                .whereType<FotoBarangModel>()
                .toList();

        developer.log(
          '\nBerhasil parse ${fotoList.length} foto dari list langsung',
        );
        return fotoList;
      }

      developer.log('\n=== DEBUG: Unrecognized Response Format ===');
      developer.log('Response tidak sesuai format yang diharapkan');
      return [];
    } catch (e, stackTrace) {
      developer.log('\n=== DEBUG: Error in getFotoByBarangId ===');
      developer.log('Error mengambil foto barang untuk ID $idBarang: $e');
      developer.log('Stack trace: $stackTrace');
      return [];
    }
  }

  // Mendapatkan foto barang berdasarkan ID barang (endpoint baru)
  Future<List<FotoBarangModel>> getFotoBarangByIdBarang(int idBarang) async {
    try {
      developer.log('\n=== DEBUG: getFotoBarangByIdBarang ===');
      developer.log('Mengambil foto untuk barang ID: $idBarang');

      final response = await _apiService.get('$apiUrl/barang/$idBarang');

      if (response == null) {
        developer.log('Response null dari API foto barang');
        return [];
      }

      final JsonEncoder encoder = JsonEncoder.withIndent('  ');
      developer.log('\n=== DEBUG: Raw API Response ===');
      developer.log('Response Type: ${response.runtimeType}');
      developer.log('Response Content:');
      developer.log(encoder.convert(response));

      if (response is List) {
        final fotoList =
            response.map((item) => FotoBarangModel.fromJson(item)).toList();

        developer.log('Berhasil mendapatkan ${fotoList.length} foto');
        return fotoList;
      }

      // Handle response dalam format {success: true, data: [...]}
      if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['success'] == true) {
        final dataList = response['data'] as List;
        final fotoList =
            dataList.map((item) => FotoBarangModel.fromJson(item)).toList();

        developer.log(
          'Berhasil mendapatkan ${fotoList.length} foto dari response data',
        );
        return fotoList;
      }

      developer.log('Format response tidak dikenali');
      return [];
    } catch (e, stackTrace) {
      developer.log('Error mengambil foto barang: $e');
      developer.log('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<FotoBarangModel?> getThumbnailFoto(int idBarang) async {
    try {
      final List<FotoBarangModel> fotos = await getFotoByBarangId(idBarang);

      if (fotos.isEmpty) {
        developer.log('Tidak ada foto untuk barang ID: $idBarang');
        return null;
      }

      // Cari foto dengan is_thumbnail = true
      final thumbnail = fotos.firstWhere(
        (foto) => foto.isThumbnail == true,
        orElse: () => fotos.first, // Jika tidak ada, gunakan foto pertama
      );

      developer.log('Thumbnail ditemukan:');
      developer.log('- ID: ${thumbnail.idFotoBarang}');
      developer.log('- URL: ${thumbnail.urlFoto}');
      developer.log('- Is Thumbnail: ${thumbnail.isThumbnail}');

      return thumbnail;
    } catch (error, stackTrace) {
      developer.log("Error mengambil thumbnail foto: $error");
      developer.log("Stack trace: $stackTrace");
      return null;
    }
  }
}
