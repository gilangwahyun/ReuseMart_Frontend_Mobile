class FotoBarangModel {
  final int idFotoBarang;
  final int idBarang;
  final String urlFoto;
  final bool isThumbnail;

  FotoBarangModel({
    required this.idFotoBarang,
    required this.idBarang,
    required this.urlFoto,
    required this.isThumbnail,
  });

  factory FotoBarangModel.fromJson(Map<String, dynamic> json) {
    return FotoBarangModel(
      idFotoBarang: json['id_foto_barang'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      urlFoto: json['url_foto'] ?? '',
      isThumbnail: json['is_thumbnail'] == true || json['is_thumbnail'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_foto_barang': idFotoBarang,
      'id_barang': idBarang,
      'url_foto': urlFoto,
      'is_thumbnail': isThumbnail,
    };
  }
}
