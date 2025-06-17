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

      print(
        "Mencoba ambil profil untuk user ID: $idUser, role: ${userData['role']}",
      );

      // Coba ambil data user langsung dari API
      try {
        final userResponse = await _apiService.get('$apiUrl/$idUser');
        print(
          "Response dari API user/$idUser: ${userResponse != null ? 'ditemukan' : 'null'}",
        );

        // Update token dalam user data jika ada perubahan
        if (userResponse != null) {
          final token = await LocalStorage.getToken();
          if (token != null) {
            userResponse['token'] = token;
          }

          // Simpan data user terbaru
          await LocalStorage.saveUserMap(userResponse);
          print("Data user dari API disimpan ke local storage");
        }
      } catch (e) {
        print("Error mengambil data user dari API: $e");
        // Lanjutkan dengan data lokal yang ada
      }

      // Buat UserModel dari data lokal terbaru
      final updatedUserData = await LocalStorage.getUserMap() ?? userData;
      final user = UserModel.fromJson(updatedUserData);

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
      print("Mencoba mendapatkan data pembeli untuk user ID: ${user.idUser}");
      final response = await _apiService.get('pembeli/user/${user.idUser}');

      // Log respons lengkap untuk debugging
      print(
        "Respons dari API pembeli/user/${user.idUser}: ${response != null ? 'ditemukan' : 'null'}",
      );

      if (response == null) {
        print("Respons API null, menggunakan data user saja");
        return UserProfileModel(user: user);
      }

      try {
        PembeliModel pembeli;

        if (response is Map && response.containsKey('success')) {
          // Format respons dengan field success
          if (response['success'] == true && response.containsKey('data')) {
            print("Data pembeli ditemukan dengan format success:true");

            pembeli = PembeliModel.fromJson(
              response['data'] as Map<String, dynamic>,
            );

            // Simpan ID pembeli ke local storage
            await LocalStorage.savePembeliId(pembeli.idPembeli);
            print("ID pembeli disimpan: ${pembeli.idPembeli}");
          } else {
            print(
              "Format respons valid tapi success:false atau data tidak ada",
            );
            return UserProfileModel(user: user);
          }
        } else {
          // Format respons lama (langsung object)
          print(
            "Data pembeli ditemukan dengan format lama (tanpa success field)",
          );

          pembeli = PembeliModel.fromJson(response as Map<String, dynamic>);

          // Simpan ID pembeli ke local storage
          await LocalStorage.savePembeliId(pembeli.idPembeli);
          print("ID pembeli disimpan: ${pembeli.idPembeli}");
        }

        // Buat dan simpan profil lengkap
        final profileModel = UserProfileModel(user: user, pembeli: pembeli);
        await LocalStorage.saveProfile(profileModel);
        print("Profil lengkap dengan data pembeli disimpan ke local storage");

        return profileModel;
      } catch (e) {
        print("Error saat parsing data pembeli: $e");
        print("Data respons yang menyebabkan error: $response");
        return UserProfileModel(user: user);
      }
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
      print(
        "Respons dari API penitip/user/${user.idUser}: ${response != null ? 'ditemukan' : 'null'}",
      );

      // Periksa format respons dengan lebih teliti
      if (response == null) {
        print("Respons API null, menggunakan data user saja");
        return UserProfileModel(user: user);
      }

      try {
        if (response is Map && response.containsKey('success')) {
          // Format respons baru dengan field success
          if (response['success'] == true && response.containsKey('data')) {
            print("Data penitip ditemukan dengan format success:true");
            print(
              "Keys dalam data penitip: ${(response['data'] as Map<String, dynamic>).keys.toList()}",
            );

            final PenitipModel penitip = PenitipModel.fromJson(
              response['data'] as Map<String, dynamic>,
            );

            // Simpan ID penitip untuk referensi cepat
            await LocalStorage.savePenitipId(penitip.idPenitip.toString());
            print("ID penitip disimpan: ${penitip.idPenitip}");

            // Buat dan kembalikan profil lengkap
            final profileModel = UserProfileModel(user: user, penitip: penitip);

            // Simpan profil lengkap ke local storage
            await LocalStorage.saveProfile(profileModel);
            print(
              "Profil lengkap dengan data penitip disimpan ke local storage",
            );

            return profileModel;
          } else {
            print(
              "Format respons valid tapi success:false atau data tidak ada",
            );
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

          // Simpan ID penitip
          await LocalStorage.savePenitipId(penitip.idPenitip.toString());

          // Buat dan simpan profil lengkap
          final profileModel = UserProfileModel(user: user, penitip: penitip);
          await LocalStorage.saveProfile(profileModel);

          return profileModel;
        }
      } catch (e) {
        print("Error saat parsing data penitip: $e");
        print("Data respons yang menyebabkan error: $response");
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
