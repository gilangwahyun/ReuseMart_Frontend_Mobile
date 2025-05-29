import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/local_storage.dart';
import 'api_service.dart';
import 'user_api.dart';

class AuthApi {
  final ApiService _apiService = ApiService();

  // URL dasar tanpa /api untuk endpoint auth
  final String baseAuthUrl = BASE_URL;

  // Login
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('login', data);

      // Pastikan response ada dan memiliki token
      if (response != null && response['token'] != null) {
        // Simpan token dan data user di SharedPreferences
        await LocalStorage.saveToken(response['token']);

        if (response['data'] != null) {
          // Membuat model user dan menyimpannya
          final userData = response['data'] as Map<String, dynamic>;
          userData['token'] = response['token'];
          final user = UserModel.fromJson(userData);
          await LocalStorage.saveUser(user);

          // Simpan juga data sebagai Map untuk akses mudah
          await LocalStorage.saveUserMap(userData);

          // Log berhasil menyimpan data
          print('Token dan data user berhasil disimpan');

          // Coba ambil data profil lengkap
          try {
            final userApi = UserApi();
            final profile = await userApi.getProfile();
            await LocalStorage.saveProfile(profile);
            print('Data profil lengkap berhasil disimpan');
          } catch (e) {
            print('Gagal mengambil data profil lengkap: $e');
            // Lanjutkan proses login meskipun gagal mengambil profil
          }
        } else {
          throw Exception('Data user tidak ditemukan dalam response');
        }
      } else {
        throw Exception('Token tidak ditemukan dalam response');
      }

      return response;
    } catch (error) {
      print("Login error: $error");
      throw error;
    }
  }

  // Logout
  Future<dynamic> logout() async {
    try {
      final response = await _apiService.post('logout', {});

      // Hapus token dan data user
      await LocalStorage.clearAuthData();

      print("Logout berhasil, token dan data user dihapus");
      return response;
    } catch (error) {
      print("Logout error: $error");
      throw error;
    }
  }

  // Get user profile
  Future<dynamic> getProfile() async {
    try {
      final userData = await LocalStorage.getUserMap();
      if (userData == null) {
        throw Exception('User data tidak ditemukan');
      }

      final idUser = userData['id_user'];
      if (idUser == null) {
        throw Exception('ID User tidak ditemukan');
      }

      final response = await _apiService.get('user/$idUser');
      return response;
    } catch (error) {
      print("Get profile error: $error");
      throw error;
    }
  }

  // Check login status
  Future<bool> isLoggedIn() async {
    final token = await LocalStorage.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // Dapatkan user data dari localStorage
    final userData = await LocalStorage.getUserMap();
    if (userData == null) {
      return false;
    }

    final idUser = userData['id_user'];
    if (idUser == null) {
      return false;
    }

    // Validasi token dengan mencoba request yang memerlukan auth
    try {
      // Coba ambil data user dari backend
      await _apiService.get('user/$idUser');
      return true;
    } catch (e) {
      print("Token validation error: $e");
      return false;
    }
  }

  // Check token exists locally without server validation
  Future<bool> hasLocalToken() async {
    return await LocalStorage.isLoggedIn();
  }

  // Get user data from local storage
  Future<Map<String, dynamic>?> getUserData() async {
    return await LocalStorage.getUserMap();
  }
}
