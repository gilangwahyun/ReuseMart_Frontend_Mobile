import 'api_service.dart';
import 'dart:developer' as developer;

class BadgeApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = 'badge';

  BadgeApi() {
    // Enable debug mode untuk ApiService
    ApiService.setDebugMode(true);
  }

  Future<Map<String, dynamic>?> getTopSeller(String idPenitip) async {
    developer.log('\n=== BADGE API CALL START ===');
    try {
      developer.log('BADGE API: Mencari badge untuk ID Penitip: $idPenitip');
      developer.log(
        'BADGE API: URL yang akan dipanggil: get-top-seller/$idPenitip',
      );

      final response = await _apiService.get(
        '$apiUrl/get-top-seller/$idPenitip',
      );

      developer.log('BADGE API: Raw response: ${response.toString()}');

      // Pengecekan response yang lebih detail
      if (response == null) {
        developer.log('BADGE API: Response adalah null');
        developer.log('=== BADGE API CALL END ===\n');
        return null;
      }

      if (response is! Map<String, dynamic>) {
        developer.log(
          'BADGE API: Response bukan Map - Type: ${response.runtimeType}',
        );
        developer.log('=== BADGE API CALL END ===\n');
        return null;
      }

      // Pengecekan format response
      if (response['message'] == null) {
        developer.log('BADGE API: Response tidak memiliki field "message"');
        developer.log('=== BADGE API CALL END ===\n');
        return null;
      }

      if (response['data'] == null) {
        developer.log('BADGE API: Response tidak memiliki field "data"');
        developer.log('=== BADGE API CALL END ===\n');
        return response; // Tetap kembalikan response untuk menangani kasus "tidak ditemukan"
      }

      // Response valid
      developer.log('BADGE API: Badge ditemukan');
      developer.log('BADGE API: Message: ${response['message']}');
      developer.log('BADGE API: Data: ${response['data']}');

      if (response['data'] is Map) {
        if (response['data']['nama_badge'] != null) {
          developer.log(
            'BADGE API: Nama Badge: ${response['data']['nama_badge']}',
          );
        }
        if (response['data']['deskripsi'] != null) {
          developer.log(
            'BADGE API: Deskripsi: ${response['data']['deskripsi']}',
          );
        }
        if (response['data']['penitip'] != null) {
          developer.log('BADGE API: Data Penitip tersedia');
          developer.log(
            'BADGE API: Nama Penitip: ${response['data']['penitip']['nama_penitip']}',
          );
        }
      }

      developer.log('=== BADGE API CALL END ===\n');
      return response;
    } catch (e) {
      developer.log('BADGE API: Error: $e');
      developer.log('=== BADGE API CALL END ===\n');
      return null;
    }
  }
}
