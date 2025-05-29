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
  });

  factory PenitipModel.fromJson(Map<String, dynamic> json) {
    return PenitipModel(
      idPenitip: json['id_penitip'] ?? 0,
      idUser: json['id_user'] ?? 0,
      namaPenitip: json['nama_penitip'] ?? '',
      nik: json['nik'] ?? '',
      nomorKtp: json['nomor_ktp'],
      fotoKtp: json['foto_ktp'],
      noTelepon: json['no_telepon'] ?? '',
      alamat: json['alamat'] ?? '',
      saldo:
          json['saldo'] != null ? double.parse(json['saldo'].toString()) : null,
      jumlahPoin: json['jumlah_poin'],
    );
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
    );
  }
}
