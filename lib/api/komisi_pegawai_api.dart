import 'api_service.dart';
import '../models/komisi_pegawai_model.dart';

class KomisiPegawaiApi {
  final ApiService _apiService = ApiService();

  Future<List<KomisiPegawaiModel>> getKomisiByPegawai(int idPegawai) async {
    try {
      final response = await _apiService.get(
        'komisiPegawai',
        queryParameters: {'id_pegawai': idPegawai.toString()},
      );

      if (response is List) {
        return response.map((item) => KomisiPegawaiModel.fromJson(item)).toList();
      } else if (response is Map && response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => KomisiPegawaiModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Unexpected response format: $response');
      }
    } catch (e) {
      print('Error fetching komisi for pegawai: $e');
      return [];
    }
  }
  
  Future<KomisiPegawaiModel?> getKomisiById(int idKomisi) async {
    try {
      final response = await _apiService.get('komisiPegawai/$idKomisi');
      
      if (response != null) {
        if (response is Map) {
          if (response.containsKey('data')) {
            return KomisiPegawaiModel.fromJson(response['data'] as Map<String, dynamic>);
          } else {
            return KomisiPegawaiModel.fromJson(response as Map<String, dynamic>);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching komisi details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getLaporanKomisiHunterBulanan(int idPegawai, {int? tahun, int? bulan}) async {
    try {
      Map<String, String> queryParams = {
        'id_pegawai': idPegawai.toString(),
      };
      
      if (tahun != null) {
        queryParams['tahun'] = tahun.toString();
      }
      
      if (bulan != null) {
        queryParams['bulan'] = bulan.toString();
      }
      
      final response = await _apiService.get(
        'komisiPegawai/laporan',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      print('Error fetching komisi hunter report: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<double> getTotalKomisiPegawai(int idPegawai) async {
    try {
      final komisiList = await getKomisiByPegawai(idPegawai);
      double totalKomisi = 0;
      
      for (var komisi in komisiList) {
        totalKomisi += komisi.jumlahKomisi;
      }
      
      return totalKomisi;
    } catch (e) {
      print('Error calculating total komisi: $e');
      return 0;
    }
  }
} 