class FotoBarangModel {
  final int idFotoBarang;
  final int idBarang;
  final String urlFoto;
  final int? isThumbnail;

  FotoBarangModel({
    required this.idFotoBarang,
    required this.idBarang,
    required this.urlFoto,
    this.isThumbnail,
  });

  factory FotoBarangModel.fromJson(Map<String, dynamic> json) {
    return FotoBarangModel(
      idFotoBarang: json['id_foto_barang'],
      idBarang: json['id_barang'],
      urlFoto: json['url_foto'] ?? '',
      isThumbnail: json['is_thumbnail'],
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
