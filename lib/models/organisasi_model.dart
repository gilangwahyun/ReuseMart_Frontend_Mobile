import 'user_model.dart';

class OrganisasiModel {
  final int idOrganisasi;
  final int idUser;
  final String namaOrganisasi;
  final String alamat;
  final String noTelepon;
  final String? deskripsi;
  final String? noNpwp;
  final String? fotoBuktiLegalitas;
  final UserModel? user;

  OrganisasiModel({
    required this.idOrganisasi,
    required this.idUser,
    required this.namaOrganisasi,
    required this.alamat,
    required this.noTelepon,
    this.deskripsi,
    this.noNpwp,
    this.fotoBuktiLegalitas,
    this.user,
  });

  factory OrganisasiModel.fromJson(Map<String, dynamic> json) {
    return OrganisasiModel(
      idOrganisasi: json['id_organisasi'] ?? 0,
      idUser: json['id_user'] ?? 0,
      namaOrganisasi: json['nama_organisasi'] ?? '',
      alamat: json['alamat'] ?? '',
      noTelepon: json['no_telepon'] ?? '',
      deskripsi: json['deskripsi'],
      noNpwp: json['no_npwp'],
      fotoBuktiLegalitas: json['foto_bukti_legalitas'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_organisasi': idOrganisasi,
      'id_user': idUser,
      'nama_organisasi': namaOrganisasi,
      'alamat': alamat,
      'no_telepon': noTelepon,
      'deskripsi': deskripsi,
      'no_npwp': noNpwp,
      'foto_bukti_legalitas': fotoBuktiLegalitas,
    };
  }
}
