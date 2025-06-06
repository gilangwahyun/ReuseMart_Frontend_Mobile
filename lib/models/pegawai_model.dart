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
    return PegawaiModel(
      idPegawai: json['id_pegawai'],
      idJabatan: json['id_jabatan'],
      idUser: json['id_user'],
      namaPegawai: json['nama_pegawai'],
      tanggalLahir: json['tanggal_lahir'],
      noTelepon: json['no_telepon'],
      alamat: json['alamat'],
      jabatan: json['jabatan'],
      user: json['user'],
    );
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
