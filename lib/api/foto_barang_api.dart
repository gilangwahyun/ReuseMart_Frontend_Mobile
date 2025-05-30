import 'api_service.dart';
import '../models/foto_barang_model.dart';

class FotoBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/fotoBarang';

  Future<List<FotoBarangModel>> getFotoByBarangId(int idBarang) async {
    try {
      final response = await _apiService.get('$apiUrl/$idBarang');

      if (response != null && response['success'] && response['data'] != null) {
        List<dynamic> data = response['data'];
        return data.map((item) => FotoBarangModel.fromJson(item)).toList();
      }

      return [];
    } catch (error) {
      print("Error mengambil foto barang: $error");
      return [];
    }
  }

  Future<FotoBarangModel?> getThumbnailFoto(int idBarang) async {
    try {
      final fotos = await getFotoByBarangId(idBarang);

      if (fotos.isEmpty) {
        return null;
      }

      // Cari foto dengan is_thumbnail = 1
      final thumbnail = fotos.firstWhere(
        (foto) => foto.isThumbnail == 1,
        orElse: () => fotos.first, // Jika tidak ada, gunakan foto pertama
      );

      return thumbnail;
    } catch (error) {
      print("Error mengambil thumbnail foto: $error");
      return null;
    }
  }
}
