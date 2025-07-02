import 'user_model.dart';
import 'dart:developer' as developer;

class PenitipModel {
  final int idPenitip;
  final int idUser;
  final String namaPenitip;
  final String nik;
  final String? nomorKtp;
  final String? fotoKtp;
  final String noTelepon;
  final String alamat;
  final double? saldo;
  final int? jumlahPoin;
  final UserModel? user;

  PenitipModel({
    required this.idPenitip,
    required this.idUser,
    required this.namaPenitip,
    required this.nik,
    this.nomorKtp,
    this.fotoKtp,
    required this.noTelepon,
    required this.alamat,
    this.saldo,
    this.jumlahPoin,
    this.user,
  });

  factory PenitipModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('=== DEBUG: Parsing PenitipModel ===');
      developer.log('Raw JSON: $json');

      // Helper functions untuk parsing nilai yang mungkin string
      int parseIntValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          final result = int.tryParse(value);
          if (result == null) {
            developer.log(
              'WARNING: Failed to parse "$value" as int, defaulting to 0',
            );
            return 0;
          }
          return result;
        }
        return 0;
      }

      double parseDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final result = double.tryParse(value);
          if (result == null) {
            developer.log(
              'WARNING: Failed to parse "$value" as double, defaulting to 0.0',
            );
            return 0.0;
          }
          return result;
        }
        return 0.0;
      }

      // Parse user jika tersedia
      UserModel? userData;
      if (json['user'] != null) {
        try {
          userData = UserModel.fromJson(json['user']);
          developer.log('Successfully parsed user data: ${userData.email}');
        } catch (e) {
          developer.log('Error parsing user data: $e');
        }
      }

      final idPenitip = parseIntValue(json['id_penitip']);
      final idUser = parseIntValue(json['id_user']);
      final namaPenitip = json['nama_penitip'] ?? '';

      developer.log('Parsed values:');
      developer.log('- idPenitip: $idPenitip (from: ${json['id_penitip']})');
      developer.log('- idUser: $idUser (from: ${json['id_user']})');
      developer.log('- namaPenitip: $namaPenitip');

      return PenitipModel(
        idPenitip: idPenitip,
        idUser: idUser,
        namaPenitip: namaPenitip,
        nik: json['nik'] ?? '',
        nomorKtp: json['nomor_ktp'],
        fotoKtp: json['foto_ktp'],
        noTelepon: json['no_telepon'] ?? '',
        alamat: json['alamat'] ?? '',
        saldo: parseDoubleValue(json['saldo']),
        jumlahPoin: parseIntValue(json['jumlah_poin']),
        user: userData,
      );
    } catch (e) {
      developer.log("Error parsing PenitipModel: $e");
      developer.log("JSON: $json");

      // Fallback dengan nilai default untuk menghindari crash
      return PenitipModel(
        idPenitip: 0,
        idUser: 0,
        namaPenitip: 'Error: ${e.toString().substring(0, 20)}...',
        nik: '',
        noTelepon: '',
        alamat: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penitip': idPenitip,
      'id_user': idUser,
      'nama_penitip': namaPenitip,
      'nik': nik,
      'nomor_ktp': nomorKtp,
      'foto_ktp': fotoKtp,
      'no_telepon': noTelepon,
      'alamat': alamat,
      'saldo': saldo,
      'jumlah_poin': jumlahPoin,
    };
  }

  PenitipModel copyWith({
    int? idPenitip,
    int? idUser,
    String? namaPenitip,
    String? nik,
    String? nomorKtp,
    String? fotoKtp,
    String? noTelepon,
    String? alamat,
    double? saldo,
    int? jumlahPoin,
    UserModel? user,
  }) {
    return PenitipModel(
      idPenitip: idPenitip ?? this.idPenitip,
      idUser: idUser ?? this.idUser,
      namaPenitip: namaPenitip ?? this.namaPenitip,
      nik: nik ?? this.nik,
      nomorKtp: nomorKtp ?? this.nomorKtp,
      fotoKtp: fotoKtp ?? this.fotoKtp,
      noTelepon: noTelepon ?? this.noTelepon,
      alamat: alamat ?? this.alamat,
      saldo: saldo ?? this.saldo,
      jumlahPoin: jumlahPoin ?? this.jumlahPoin,
      user: user ?? this.user,
    );
  }
}
