import 'dart:convert';
import 'api_service.dart';

class JadwalApi {
  final ApiService _apiService = ApiService();

  // Get all jadwal
  Future<List<dynamic>> getAllJadwal() async {
    try {
      final response = await _apiService.get('jadwal');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get jadwal by ID
  Future<dynamic> getJadwalById(int id) async {
    try {
      final response = await _apiService.get('jadwal/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get jadwal by pegawai ID
  // Since the backend doesn't have a specific route for this,
  // we'll get all jadwal and filter by pegawai ID
  Future<List<dynamic>> getJadwalByPegawai(int idPegawai) async {
    try {
      final response = await _apiService.get('jadwal');
      if (response is List) {
        // Filter the jadwal list by pegawai ID
        return response
            .where(
              (jadwal) =>
                  jadwal['id_pegawai'] != null &&
                  jadwal['id_pegawai'] == idPegawai,
            )
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Update jadwal status
  Future<dynamic> updateJadwalStatus(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('jadwal/$id', data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
