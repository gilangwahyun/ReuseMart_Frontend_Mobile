class BarangPenitipanModel {
  final int idBarang;
  final String namaBarang;
  final String? deskripsi;
  final double harga;
  final String? masaGaransi;
  final double? berat;
  final double? rating;
  final String statusBarang;
  final int idKategori;
  final int idPenitipan;
  final String? gambarUtama;

  BarangPenitipanModel({
    required this.idBarang,
    required this.namaBarang,
    this.deskripsi,
    required this.harga,
    this.masaGaransi,
    this.berat,
    this.rating,
    required this.statusBarang,
    required this.idKategori,
    required this.idPenitipan,
    this.gambarUtama,
  });

  factory BarangPenitipanModel.fromJson(Map<String, dynamic> json) {
    return BarangPenitipanModel(
      idBarang: json['id_barang'],
      namaBarang: json['nama_barang'],
      deskripsi: json['deskripsi'],
      harga: double.parse(json['harga'].toString()),
      masaGaransi: json['masa_garansi'],
      berat:
          json['berat'] != null ? double.parse(json['berat'].toString()) : null,
      rating:
          json['rating'] != null
              ? double.parse(json['rating'].toString())
              : null,
      statusBarang: json['status_barang'],
      idKategori: json['id_kategori'],
      idPenitipan: json['id_penitipan'],
      gambarUtama: json['gambar_utama'],
    );
  }
}
