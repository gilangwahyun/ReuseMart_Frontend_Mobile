class FotoBarangModel {
  final int idFotoBarang;
  final int idBarang;
  final String url;
  final bool? isUtama;

  FotoBarangModel({
    required this.idFotoBarang,
    required this.idBarang,
    required this.url,
    this.isUtama,
  });

  factory FotoBarangModel.fromJson(Map<String, dynamic> json) {
    return FotoBarangModel(
      idFotoBarang: json['id_foto_barang'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      url: json['url'] ?? '',
      isUtama: json['is_utama'] == 1 || json['is_utama'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_foto_barang': idFotoBarang,
      'id_barang': idBarang,
      'url': url,
      'is_utama': isUtama,
    };
  }
}
