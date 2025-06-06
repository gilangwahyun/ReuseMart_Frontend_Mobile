import 'dart:convert';
import 'api_service.dart';

class PegawaiApi {
  final ApiService _apiService = ApiService();

  // Get pegawai data by user ID
  Future<dynamic> getPegawaiByUserId(int userId) async {
    try {
      final response = await _apiService.get('/pegawai/user/$userId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get pegawai data by pegawai ID
  Future<dynamic> getPegawaiById(int id) async {
    try {
      final response = await _apiService.get('pegawai/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update pegawai profile
  Future<dynamic> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('pegawai/$id', data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get jabatan by user ID
  Future<dynamic> getJabatanByUser(int userId) async {
    try {
      final response = await _apiService.get('pegawai/user/$userId/jabatan');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
