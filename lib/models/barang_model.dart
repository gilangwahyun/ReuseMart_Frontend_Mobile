import 'kategori_barang_model.dart';
import 'penitipan_barang_model.dart';
import 'foto_barang_model.dart';

class BarangModel {
  final int idBarang;
  final int idKategori;
  final int idPenitipan;
  final String namaBarang;
  final String? deskripsi;
  final double harga;
  final String? masaGaransi;
  final double? berat;
  final double? rating;
  final String statusBarang;
  final KategoriBarangModel? kategori;
  final PenitipanBarangModel? penitipanBarang;
  final List<FotoBarangModel>? fotoBarang;

  BarangModel({
    required this.idBarang,
    required this.idKategori,
    required this.idPenitipan,
    required this.namaBarang,
    this.deskripsi,
    required this.harga,
    this.masaGaransi,
    this.berat,
    this.rating,
    required this.statusBarang,
    this.kategori,
    this.penitipanBarang,
    this.fotoBarang,
  });

  String get gambarUtama {
    if (fotoBarang != null && fotoBarang!.isNotEmpty) {
      // Cari foto yang bertanda thumbnail
      final thumbnail = fotoBarang!.firstWhere(
        (foto) => foto.isThumbnail == 1,
        orElse: () => fotoBarang!.first,
      );
      return thumbnail.urlFoto;
    }
    return '';
  }

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    // Parse kategori jika tersedia
    KategoriBarangModel? kategoriData;
    if (json['kategori'] != null) {
      kategoriData = KategoriBarangModel.fromJson(json['kategori']);
    }

    // Parse penitipan barang jika tersedia
    PenitipanBarangModel? penitipanData;
    if (json['penitipan_barang'] != null) {
      penitipanData = PenitipanBarangModel.fromJson(json['penitipan_barang']);
    } else if (json['penitipanBarang'] != null) {
      penitipanData = PenitipanBarangModel.fromJson(json['penitipanBarang']);
    }

    // Parse foto barang jika tersedia
    List<FotoBarangModel>? fotoData;
    if (json['foto_barang'] != null) {
      fotoData =
          (json['foto_barang'] as List)
              .map((item) => FotoBarangModel.fromJson(item))
              .toList();
    } else if (json['fotoBarang'] != null) {
      fotoData =
          (json['fotoBarang'] as List)
              .map((item) => FotoBarangModel.fromJson(item))
              .toList();
    }

    return BarangModel(
      idBarang: json['id_barang'],
      idKategori: json['id_kategori'],
      idPenitipan: json['id_penitipan'],
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
      kategori: kategoriData,
      penitipanBarang: penitipanData,
      fotoBarang: fotoData,
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
    };
  }

  BarangModel copyWith({
    int? idBarang,
    int? idKategori,
    int? idPenitipan,
    String? namaBarang,
    String? deskripsi,
    double? harga,
    String? masaGaransi,
    double? berat,
    double? rating,
    String? statusBarang,
    KategoriBarangModel? kategori,
    PenitipanBarangModel? penitipanBarang,
    List<FotoBarangModel>? fotoBarang,
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
      kategori: kategori ?? this.kategori,
      penitipanBarang: penitipanBarang ?? this.penitipanBarang,
      fotoBarang: fotoBarang ?? this.fotoBarang,
    );
  }
}
