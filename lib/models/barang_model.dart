class BarangModel {
  final int idBarang;
  final int? idKategori;
  final int? idPenitipan;
  final String namaBarang;
  final String? deskripsi;
  final int harga;
  final String? masaGaransi;
  final double? berat;
  final double? rating;
  final String statusBarang;
  final String? kondisiBarang;
  // Field tambahan untuk tampilan
  final String? kategoriNama;

  BarangModel({
    required this.idBarang,
    this.idKategori,
    this.idPenitipan,
    required this.namaBarang,
    this.deskripsi,
    required this.harga,
    this.masaGaransi,
    this.berat,
    this.rating,
    required this.statusBarang,
    this.kondisiBarang,
    this.kategoriNama,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      idBarang: json['id_barang'] ?? 0,
      idKategori: json['id_kategori'],
      idPenitipan: json['id_penitipan'],
      namaBarang: json['nama_barang'] ?? '',
      deskripsi: json['deskripsi'],
      harga: json['harga'] ?? 0,
      masaGaransi: json['masa_garansi'],
      berat:
          json['berat'] != null ? double.parse(json['berat'].toString()) : null,
      rating:
          json['rating'] != null
              ? double.parse(json['rating'].toString())
              : null,
      statusBarang: json['status_barang'] ?? '',
      kondisiBarang: json['kondisi_barang'],
      kategoriNama:
          json['kategori'] != null ? json['kategori']['nama_kategori'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_barang': idBarang,
      'id_kategori': idKategori,
      'id_penitipan': idPenitipan,
      'nama_barang': namaBarang,
      'deskripsi': deskripsi,
      'harga': harga,
      'masa_garansi': masaGaransi,
      'berat': berat,
      'rating': rating,
      'status_barang': statusBarang,
      'kondisi_barang': kondisiBarang,
    };
  }

  BarangModel copyWith({
    int? idBarang,
    int? idKategori,
    int? idPenitipan,
    String? namaBarang,
    String? deskripsi,
    int? harga,
    String? masaGaransi,
    double? berat,
    double? rating,
    String? statusBarang,
    String? kondisiBarang,
    String? kategoriNama,
  }) {
    return BarangModel(
      idBarang: idBarang ?? this.idBarang,
      idKategori: idKategori ?? this.idKategori,
      idPenitipan: idPenitipan ?? this.idPenitipan,
      namaBarang: namaBarang ?? this.namaBarang,
      deskripsi: deskripsi ?? this.deskripsi,
      harga: harga ?? this.harga,
      masaGaransi: masaGaransi ?? this.masaGaransi,
      berat: berat ?? this.berat,
      rating: rating ?? this.rating,
      statusBarang: statusBarang ?? this.statusBarang,
      kondisiBarang: kondisiBarang ?? this.kondisiBarang,
      kategoriNama: kategoriNama ?? this.kategoriNama,
    );
  }
}
