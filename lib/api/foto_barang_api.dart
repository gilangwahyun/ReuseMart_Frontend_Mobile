import 'api_service.dart';
import '../models/foto_barang_model.dart';

class FotoBarangApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = 'fotoBarang';

  // Mendapatkan semua foto barang berdasarkan ID barang
  Future<dynamic> getFotoByBarangId(int idBarang) async {
    try {
      // Gunakan endpoint yang sesuai untuk mendapatkan foto berdasarkan ID barang
      final response = await _apiService.get('$apiUrl/barang/$idBarang');
      return response;
    } catch (e) {
      print('Error mengambil foto barang: $e');
      throw e;
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
