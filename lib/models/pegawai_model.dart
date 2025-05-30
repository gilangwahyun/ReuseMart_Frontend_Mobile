class PegawaiModel {
  final int idPegawai;
  final int? idUser;
  final int? idJabatan;
  final String namaPegawai;
  final String nikPegawai;
  final String alamatPegawai;
  final String teleponPegawai;
  final String emailPegawai;
  final String? fotoPegawai;

  PegawaiModel({
    required this.idPegawai,
    this.idUser,
    this.idJabatan,
    required this.namaPegawai,
    required this.nikPegawai,
    required this.alamatPegawai,
    required this.teleponPegawai,
    required this.emailPegawai,
    this.fotoPegawai,
  });

  factory PegawaiModel.fromJson(Map<String, dynamic> json) {
    return PegawaiModel(
      idPegawai: json['id_pegawai'],
      idUser: json['id_user'],
      idJabatan: json['id_jabatan'],
      namaPegawai: json['nama_pegawai'] ?? '',
      nikPegawai: json['nik_pegawai'] ?? '',
      alamatPegawai: json['alamat_pegawai'] ?? '',
      teleponPegawai: json['telepon_pegawai'] ?? '',
      emailPegawai: json['email_pegawai'] ?? '',
      fotoPegawai: json['foto_pegawai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pegawai': idPegawai,
      'id_user': idUser,
      'id_jabatan': idJabatan,
      'nama_pegawai': namaPegawai,
      'nik_pegawai': nikPegawai,
      'alamat_pegawai': alamatPegawai,
      'telepon_pegawai': teleponPegawai,
      'email_pegawai': emailPegawai,
      'foto_pegawai': fotoPegawai,
    };
  }
}
