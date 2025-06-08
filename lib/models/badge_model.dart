class BadgeModel {
  final int idBadge;
  final String namaBadge;
  final String? deskripsi;
  final int? idPenitip;

  BadgeModel({
    required this.idBadge,
    required this.namaBadge,
    this.deskripsi,
    this.idPenitip,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      idBadge: json['id_badge'],
      namaBadge: json['nama_badge'],
      deskripsi: json['deskripsi'],
      idPenitip: json['id_penitip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_badge': idBadge,
      'nama_badge': namaBadge,
      'deskripsi': deskripsi,
      'id_penitip': idPenitip,
    };
  }
}
