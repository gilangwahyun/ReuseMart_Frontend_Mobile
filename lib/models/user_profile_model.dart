import 'user_model.dart';
import 'pembeli_model.dart';
import 'penitip_model.dart';
import 'pegawai_model.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class UserProfileModel {
  final UserModel user;
  final PembeliModel? pembeli;
  final PenitipModel? penitip;
  final PegawaiModel? pegawai;

  UserProfileModel({
    required this.user,
    this.pembeli,
    this.penitip,
    this.pegawai,
  });

  String get name {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.namaPembeli;
    } else if (user.role == 'Penitip' && penitip != null) {
      return penitip!.namaPenitip;
    } else if ((user.role == 'Kurir' || user.role == 'Pegawai') &&
        pegawai != null) {
      return pegawai!.namaPegawai;
    }
    return 'User';
  }

  String get phone {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.noHpDefault;
    } else if (user.role == 'Penitip' && penitip != null) {
      return penitip!.noTelepon;
    } else if ((user.role == 'Kurir' || user.role == 'Pegawai') &&
        pegawai != null) {
      return pegawai!.noTelepon;
    }
    return '';
  }

  String? get address {
    if (user.role == 'Penitip' && penitip != null) {
      return penitip!.alamat;
    } else if ((user.role == 'Kurir' || user.role == 'Pegawai') &&
        pegawai != null) {
      return pegawai!.alamat;
    }
    return null;
  }

  int get poin {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.jumlahPoin;
    } else if (user.role == 'Penitip' &&
        penitip != null &&
        penitip!.jumlahPoin != null) {
      return penitip!.jumlahPoin!;
    }
    return 0;
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log("Parsing UserProfileModel dari: ${json.keys.toList()}");
      developer.log("JSON Data: ${jsonEncode(json)}");

      // Coba identifikasi struktur JSON yang beragam
      UserModel user;
      PembeliModel? pembeli;
      PenitipModel? penitip;
      PegawaiModel? pegawai;

      // Ekstrak user data
      if (json.containsKey('user')) {
        // Format 1: { user: {...}, penitip/pembeli: {...} }
        developer.log("Format JSON dengan key 'user' terdeteksi");
        user = UserModel.fromJson(json['user']);
      } else if (json.containsKey('id_user')) {
        // Format 2: user data langsung di root objek
        developer.log("Format JSON dengan user data di root level");
        user = UserModel.fromJson(json);
      } else {
        throw Exception('Format JSON tidak valid: tidak ada data user');
      }

      // Ekstrak data penitip/pembeli/pegawai berdasarkan role
      String role = user.role.toLowerCase();
      developer.log("User role terdeteksi: $role");

      // Coba cari data penitip
      if (role == 'penitip') {
        try {
          if (json.containsKey('penitip') && json['penitip'] != null) {
            developer.log("Data penitip ditemukan dalam format JSON standard");
            penitip = PenitipModel.fromJson(json['penitip']);
          } else if (json.containsKey('data') && json['data'] != null) {
            // Format dari API: {success: true, data: {...}}
            developer.log("Data penitip ditemukan dalam format data wrapper");
            penitip = PenitipModel.fromJson(json['data']);
          }
        } catch (e) {
          developer.log("Error saat parsing data penitip: $e");
        }
      }

      // Coba cari data pembeli
      if (role == 'pembeli') {
        try {
          if (json.containsKey('pembeli') && json['pembeli'] != null) {
            developer.log("Data pembeli ditemukan dalam format JSON standard");
            pembeli = PembeliModel.fromJson(json['pembeli']);
          } else if (json.containsKey('data') && json['data'] != null) {
            // Format dari API: {success: true, data: {...}}
            developer.log("Data pembeli ditemukan dalam format data wrapper");
            var pembeliData = json['data'];
            developer.log("Data pembeli yang akan di-parse: $pembeliData");
            pembeli = PembeliModel.fromJson(pembeliData);
          }
        } catch (e) {
          developer.log("Error saat parsing data pembeli: $e");
          developer.log("Data respons yang menyebabkan error: $json");
        }
      }

      // Coba cari data pegawai/kurir
      if (role == 'kurir' || role == 'pegawai') {
        try {
          developer.log("Mencoba ekstrak data pegawai/kurir");
          if (json.containsKey('pegawai') && json['pegawai'] != null) {
            developer.log("Data pegawai ditemukan dalam format JSON standard");
            pegawai = PegawaiModel.fromJson(json['pegawai']);
          } else if (json.containsKey('data') && json['data'] != null) {
            developer.log("Data pegawai ditemukan dalam format data wrapper");
            pegawai = PegawaiModel.fromJson(json['data']);
          }
        } catch (e) {
          developer.log("Error saat parsing data pegawai: $e");
        }
      }

      return UserProfileModel(
        user: user,
        pembeli: pembeli,
        penitip: penitip,
        pegawai: pegawai,
      );
    } catch (e) {
      developer.log("Error parsing UserProfileModel: $e");
      developer.log("JSON data: ${jsonEncode(json)}");

      // Coba ekstrak user minimal
      try {
        UserModel user;
        if (json.containsKey('user')) {
          user = UserModel.fromJson(json['user']);
        } else if (json.containsKey('id_user')) {
          user = UserModel.fromJson(json);
        } else {
          throw Exception('Tidak bisa ekstrak data user minimal');
        }

        return UserProfileModel(user: user);
      } catch (innerError) {
        developer.log(
          "Fatal error dalam parsing UserProfileModel: $innerError",
        );
        // Buat user model darurat
        final emergencyUser = UserModel(
          idUser: 0,
          email: 'error@parsing.fail',
          role: 'Unknown',
        );
        return UserProfileModel(user: emergencyUser);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['user'] = user.toJson();

    if (pembeli != null) {
      data['pembeli'] = pembeli!.toJson();
    }

    if (penitip != null) {
      data['penitip'] = penitip!.toJson();
    }

    if (pegawai != null) {
      data['pegawai'] = pegawai!.toJson();
    }

    return data;
  }
}
