import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/local_storage.dart';
import '../services/firebase_service.dart';
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

          // Register FCM token ke server setelah login
          _registerFcmToken(response['token']);

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

  // Register FCM Token ke server setelah login
  Future<void> _registerFcmToken(String authToken) async {
    try {
      // Ambil token FCM
      final fcmToken = await FirebaseService.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Kirim ke server
        print('Mengirim FCM token ke server setelah login...');
        await FirebaseService.sendTokenToServer(fcmToken, authToken);

        // Setup listener untuk perubahan token
        FirebaseService.setupTokenRefreshListener(authToken);
      }
    } catch (e) {
      print('Error saat mengirim FCM token setelah login: $e');
      // Tidak throw exception agar tidak menghentikan proses login
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

  // Force logout (tanpa memanggil API)
  Future<void> forceLogout() async {
    try {
      // Hapus semua data yang tersimpan
      await clearAllCacheData();
      print("Force logout berhasil, semua cache dihapus");
    } catch (e) {
      print("Error saat force logout: $e");
      throw e;
    }
  }

  // Clear semua cache data
  Future<void> clearAllCacheData() async {
    try {
      await LocalStorage.clearAllData();
      // Tambahkan penghapusan spesifik untuk memastikan
      await LocalStorage.removeData('id_penitip');
      await LocalStorage.removeData('id_pembeli');
      print("Semua data cache berhasil dihapus");
    } catch (e) {
      print("Error saat menghapus cache: $e");
      throw e;
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
