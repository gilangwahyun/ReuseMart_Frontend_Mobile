import 'dart:developer' as developer;

class PegawaiModel {
  final int idPegawai;
  final int idJabatan;
  final int? idUser;
  final String namaPegawai;
  final String tanggalLahir;
  final String noTelepon;
  final String alamat;
  final Map<String, dynamic>? jabatan;
  final Map<String, dynamic>? user;

  PegawaiModel({
    required this.idPegawai,
    required this.idJabatan,
    this.idUser,
    required this.namaPegawai,
    required this.tanggalLahir,
    required this.noTelepon,
    required this.alamat,
    this.jabatan,
    this.user,
  });

  factory PegawaiModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function untuk parsing nilai yang mungkin string
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

      final idPegawai = parseIntValue(json['id_pegawai']);
      final idJabatan = parseIntValue(json['id_jabatan']);
      int? idUser;

      if (json['id_user'] != null) {
        idUser = parseIntValue(json['id_user']);
      }

      return PegawaiModel(
        idPegawai: idPegawai,
        idJabatan: idJabatan,
        idUser: idUser,
        namaPegawai: json['nama_pegawai'] ?? '',
        tanggalLahir: json['tanggal_lahir'] ?? '',
        noTelepon: json['no_telepon'] ?? '',
        alamat: json['alamat'] ?? '',
        jabatan: json['jabatan'],
        user: json['user'],
      );
    } catch (e) {
      developer.log('Error parsing PegawaiModel: $e');
      developer.log('JSON: $json');

      // Return default model untuk hindari crash
      return PegawaiModel(
        idPegawai: 0,
        idJabatan: 0,
        namaPegawai: 'Error',
        tanggalLahir: '',
        noTelepon: '',
        alamat: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pegawai': idPegawai,
      'id_jabatan': idJabatan,
      'id_user': idUser,
      'nama_pegawai': namaPegawai,
      'tanggal_lahir': tanggalLahir,
      'no_telepon': noTelepon,
      'alamat': alamat,
    };
  }
}
