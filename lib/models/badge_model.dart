class BadgeModel {
  final int idBadge;
  final String namaBadge;
  final String? deskripsi;
  final int? idPenitip;
  final String? lastRekapPeriode;
  final PenitipData? penitip;

  BadgeModel({
    required this.idBadge,
    required this.namaBadge,
    this.deskripsi,
    this.idPenitip,
    this.lastRekapPeriode,
    this.penitip,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      idBadge: json['id_badge'],
      namaBadge: json['nama_badge'],
      deskripsi: json['deskripsi'],
      idPenitip: json['id_penitip'],
      lastRekapPeriode: json['last_rekap_periode'],
      penitip:
          json['penitip'] != null
              ? PenitipData.fromJson(json['penitip'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_badge': idBadge,
      'nama_badge': namaBadge,
      'deskripsi': deskripsi,
      'id_penitip': idPenitip,
      'last_rekap_periode': lastRekapPeriode,
      'penitip': penitip?.toJson(),
    };
  }
}

class PenitipData {
  final int idPenitip;
  final int idUser;
  final String namaPenitip;
  final String nik;
  final String noTelepon;
  final String alamat;
  final int saldo;
  final int jumlahPoin;

  PenitipData({
    required this.idPenitip,
    required this.idUser,
    required this.namaPenitip,
    required this.nik,
    required this.noTelepon,
    required this.alamat,
    required this.saldo,
    required this.jumlahPoin,
  });

  factory PenitipData.fromJson(Map<String, dynamic> json) {
    return PenitipData(
      idPenitip: json['id_penitip'],
      idUser: json['id_user'],
      namaPenitip: json['nama_penitip'],
      nik: json['nik'],
      noTelepon: json['no_telepon'],
      alamat: json['alamat'],
      saldo: json['saldo'],
      jumlahPoin: json['jumlah_poin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penitip': idPenitip,
      'id_user': idUser,
      'nama_penitip': namaPenitip,
      'nik': nik,
      'no_telepon': noTelepon,
      'alamat': alamat,
      'saldo': saldo,
      'jumlah_poin': jumlahPoin,
    };
  }
}
