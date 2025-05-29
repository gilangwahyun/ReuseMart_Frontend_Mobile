class PembeliModel {
  final int idPembeli;
  final int idUser;
  final String namaPembeli;
  final int jumlahPoin;
  final String noHpDefault;

  PembeliModel({
    required this.idPembeli,
    required this.idUser,
    required this.namaPembeli,
    required this.jumlahPoin,
    required this.noHpDefault,
  });

  factory PembeliModel.fromJson(Map<String, dynamic> json) {
    return PembeliModel(
      idPembeli: json['id_pembeli'] ?? 0,
      idUser: json['id_user'] ?? 0,
      namaPembeli: json['nama_pembeli'] ?? '',
      jumlahPoin: json['jumlah_poin'] ?? 0,
      noHpDefault: json['no_hp_default'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pembeli': idPembeli,
      'id_user': idUser,
      'nama_pembeli': namaPembeli,
      'jumlah_poin': jumlahPoin,
      'no_hp_default': noHpDefault,
    };
  }

  PembeliModel copyWith({
    int? idPembeli,
    int? idUser,
    String? namaPembeli,
    int? jumlahPoin,
    String? noHpDefault,
  }) {
    return PembeliModel(
      idPembeli: idPembeli ?? this.idPembeli,
      idUser: idUser ?? this.idUser,
      namaPembeli: namaPembeli ?? this.namaPembeli,
      jumlahPoin: jumlahPoin ?? this.jumlahPoin,
      noHpDefault: noHpDefault ?? this.noHpDefault,
    );
  }
}
