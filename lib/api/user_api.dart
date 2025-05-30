import 'dart:convert';
import '../models/user_profile_model.dart';
import '../models/user_model.dart';
import '../models/pembeli_model.dart';
import '../models/penitip_model.dart';
import 'api_service.dart';
import '../utils/local_storage.dart';

class UserApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/user';

  Future<UserProfileModel> getProfile() async {
    try {
      // Dapatkan data user dari local storage
      final userData = await LocalStorage.getUserMap();
      if (userData == null) {
        throw Exception('User data tidak ditemukan di local storage');
      }

      final idUser = userData['id_user'];
      if (idUser == null) {
        throw Exception('ID User tidak ditemukan');
      }

      // Buat UserModel dari data lokal
      final user = UserModel.fromJson(userData);

      // Berdasarkan role, ambil data profil tambahan
      switch (user.role) {
        case 'Pembeli':
          return await _getPembeliProfile(user);
        case 'Penitip':
          return await _getPenitipProfile(user);
        default:
          return UserProfileModel(user: user);
      }
    } catch (error) {
      print("Get profile error: $error");
      throw error;
    }
  }

  Future<UserProfileModel> _getPembeliProfile(UserModel user) async {
    try {
      // Gunakan endpoint pembeli/user/{id_user} untuk mendapatkan data pembeli
      final response = await _apiService.get('pembeli/user/${user.idUser}');

      if (response == null) {
        return UserProfileModel(user: user);
      }

      final PembeliModel pembeli = PembeliModel.fromJson(response);
      return UserProfileModel(user: user, pembeli: pembeli);
    } catch (error) {
      print("Get pembeli profile error: $error");
      return UserProfileModel(user: user);
    }
  }

  Future<UserProfileModel> _getPenitipProfile(UserModel user) async {
    try {
      print("Mencoba mendapatkan data penitip untuk user ID: ${user.idUser}");
      final response = await _apiService.get('penitip/user/${user.idUser}');

      // Log respons lengkap untuk debugging
      print("Respons dari API penitip/user/${user.idUser}: $response");

      // Periksa format respons dengan lebih teliti
      if (response == null) {
        print("Respons API null, menggunakan data user saja");
        return UserProfileModel(user: user);
      }

      if (response is Map && response.containsKey('success')) {
        // Format respons baru dengan field success
        if (response['success'] == true && response.containsKey('data')) {
          print("Data penitip ditemukan dengan format success:true");
          final PenitipModel penitip = PenitipModel.fromJson(
            response['data'] as Map<String, dynamic>,
          );
          return UserProfileModel(user: user, penitip: penitip);
        } else {
          print("Format respons valid tapi success:false atau data tidak ada");
          return UserProfileModel(user: user);
        }
      } else if (response is Map) {
        // Format respons lama (langsung object)
        print(
          "Data penitip ditemukan dengan format lama (tanpa success field)",
        );
        final PenitipModel penitip = PenitipModel.fromJson(
          response as Map<String, dynamic>,
        );
        return UserProfileModel(user: user, penitip: penitip);
      }

      // Default fallback
      return UserProfileModel(user: user);
    } catch (error) {
      print("Error mendapatkan profil penitip: $error");
      // Tetap kembalikan model user meski tanpa data penitip
      return UserProfileModel(user: user);
    }
  }

  Future<dynamic> deleteUser(int id) async {
    try {
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiService.put('user', data);
    } catch (error) {
      print("Update profile error: $error");
      throw error;
    }
  }
}
