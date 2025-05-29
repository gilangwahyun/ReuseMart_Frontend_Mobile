class KategoriBarangModel {
  final int idKategoriBarang;
  final String namaKategori;

  KategoriBarangModel({
    required this.idKategoriBarang,
    required this.namaKategori,
  });

  factory KategoriBarangModel.fromJson(Map<String, dynamic> json) {
    return KategoriBarangModel(
      idKategoriBarang: json['id_kategori_barang'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kategori_barang': idKategoriBarang,
      'nama_kategori': namaKategori,
    };
  }
}
