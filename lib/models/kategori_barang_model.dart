class KategoriBarangModel {
  final int idKategori;
  final String namaKategori;
  final String? deskripsiKategori;
  final String? iconKategori;

  KategoriBarangModel({
    required this.idKategori,
    required this.namaKategori,
    this.deskripsiKategori,
    this.iconKategori,
  });

  factory KategoriBarangModel.fromJson(Map<String, dynamic> json) {
    return KategoriBarangModel(
      idKategori: json['id_kategori'],
      namaKategori: json['nama_kategori'] ?? '',
      deskripsiKategori: json['deskripsi_kategori'],
      iconKategori: json['icon_kategori'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kategori': idKategori,
      'nama_kategori': namaKategori,
      'deskripsi_kategori': deskripsiKategori,
      'icon_kategori': iconKategori,
    };
  }
}
