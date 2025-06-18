import 'kategori_barang_model.dart';
import 'penitipan_barang_model.dart';
import 'foto_barang_model.dart';
import 'detail_transaksi_model.dart';
import 'alokasi_donasi_model.dart';
import 'transaksi_model.dart';
import 'penitip_model.dart';
import 'pegawai_model.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class BarangModel {
  final int idBarang;
  final int idKategori;
  final int idPenitipan;
  final String namaBarang;
  final String deskripsi;
  final double harga;
  final String? masaGaransi;
  final int berat;
  final double rating;
  final String statusBarang;
  final KategoriBarangModel? kategori;
  final PenitipanBarangModel? penitipanBarang;
  final List<FotoBarangModel>? fotoBarang;
  final DetailTransaksiModel? detailTransaksi;
  final AlokasiDonasiModel? alokasiDonasi;

  BarangModel({
    required this.idBarang,
    required this.idKategori,
    required this.idPenitipan,
    required this.namaBarang,
    required this.deskripsi,
    required this.harga,
    this.masaGaransi,
    required this.berat,
    required this.rating,
    required this.statusBarang,
    this.kategori,
    this.penitipanBarang,
    this.fotoBarang,
    this.detailTransaksi,
    this.alokasiDonasi,
  });

  String get gambarUtama {
    print('\n=== DEBUG: gambarUtama getter ===');
    print('fotoBarang: ${fotoBarang?.length ?? 0} foto ditemukan');

    if (fotoBarang != null && fotoBarang!.isNotEmpty) {
      try {
        print('Mencari foto thumbnail...');
        // Cari foto yang bertanda utama (is_thumbnail)
        final thumbnailFoto = fotoBarang!.firstWhere(
          (foto) {
            print(
              'Checking foto: ${foto.urlFoto} - isThumbnail: ${foto.isThumbnail}',
            );
            return foto.isThumbnail;
          },
          orElse: () {
            print(
              'Thumbnail tidak ditemukan, menggunakan foto dengan ID terkecil',
            );
            // Jika tidak ada thumbnail, gunakan foto dengan ID terkecil
            final sortedFotos = List<FotoBarangModel>.from(fotoBarang!)
              ..sort((a, b) => a.idFotoBarang.compareTo(b.idFotoBarang));
            print('Foto terpilih: ${sortedFotos.first.urlFoto}');
            return sortedFotos.first;
          },
        );
        print('URL foto yang akan digunakan: ${thumbnailFoto.urlFoto}');
        return thumbnailFoto.urlFoto;
      } catch (e) {
        print("Error mengambil gambar utama: $e");
        print("Stack trace: ${StackTrace.current}");
      }
    } else {
      print('Tidak ada foto yang tersedia untuk barang ini');
    }
    return '';
  }

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    try {
      final JsonEncoder encoder = JsonEncoder.withIndent('  ');
      developer.log('\n=== DEBUG: Parsing BarangModel from JSON ===');
      developer.log('Barang ID: ${json['id_barang']}');
      developer.log('Nama Barang: ${json['nama_barang']}');
      developer.log('Raw JSON:');
      developer.log(encoder.convert(json));

      // Debug kategori
      developer.log('\n=== DEBUG: Parsing Kategori Barang ===');
      developer.log('ID Kategori: ${json['id_kategori']}');
      if (json['kategori'] != null) {
        developer.log('Kategori field exists');
        developer.log('Kategori type: ${json['kategori'].runtimeType}');
        developer.log('Kategori content:');
        developer.log(encoder.convert(json['kategori']));
      } else {
        developer.log('Kategori field is null');
      }

      // Cek field alternatif untuk kategori
      if (json['kategori_barang'] != null) {
        developer.log('Kategori alternatif (kategori_barang) ditemukan:');
        developer.log(encoder.convert(json['kategori_barang']));
      }

      // Parse kategori
      KategoriBarangModel? kategoriData;
      if (json['kategori'] != null) {
        try {
          kategoriData = KategoriBarangModel.fromJson(json['kategori']);
          developer.log(
            'Berhasil parse kategori: ${kategoriData.namaKategori}',
          );
        } catch (e) {
          developer.log('Error parsing kategori: $e');
        }
      } else if (json['kategori_barang'] != null) {
        try {
          kategoriData = KategoriBarangModel.fromJson(json['kategori_barang']);
          developer.log(
            'Berhasil parse kategori_barang: ${kategoriData.namaKategori}',
          );
        } catch (e) {
          developer.log('Error parsing kategori_barang: $e');
        }
      }

      // Parse foto barang jika tersedia
      List<FotoBarangModel>? fotoData;
      developer.log('\n=== DEBUG: Parsing Foto Barang ===');
      developer.log('Checking foto_barang field...');
      if (json['foto_barang'] != null) {
        developer.log('foto_barang field exists');
        developer.log('foto_barang type: ${json['foto_barang'].runtimeType}');
        developer.log('foto_barang content:');
        developer.log(encoder.convert(json['foto_barang']));
        try {
          fotoData =
              (json['foto_barang'] as List).map((item) {
                developer.log('\nProcessing foto item:');
                developer.log(encoder.convert(item));
                return FotoBarangModel.fromJson(item);
              }).toList();
          developer.log(
            'Successfully parsed ${fotoData.length} photos from foto_barang',
          );
          for (var foto in fotoData) {
            developer.log(
              '- Parsed foto: ID=${foto.idFotoBarang}, URL=${foto.urlFoto}, Thumbnail=${foto.isThumbnail}',
            );
          }
        } catch (e, stackTrace) {
          developer.log("Error parsing foto_barang: $e");
          developer.log("Stack trace: $stackTrace");
        }
      } else {
        developer.log('foto_barang field is null');
      }

      if (fotoData == null && json['fotoBarang'] != null) {
        developer.log('\nTrying alternative fotoBarang field...');
        developer.log('fotoBarang type: ${json['fotoBarang'].runtimeType}');
        developer.log('fotoBarang content:');
        developer.log(encoder.convert(json['fotoBarang']));
        try {
          fotoData =
              (json['fotoBarang'] as List).map((item) {
                developer.log('\nProcessing foto item:');
                developer.log(encoder.convert(item));
                return FotoBarangModel.fromJson(item);
              }).toList();
          developer.log(
            'Successfully parsed ${fotoData.length} photos from fotoBarang',
          );
          for (var foto in fotoData) {
            developer.log(
              '- Parsed foto: ID=${foto.idFotoBarang}, URL=${foto.urlFoto}, Thumbnail=${foto.isThumbnail}',
            );
          }
        } catch (e, stackTrace) {
          developer.log("Error parsing fotoBarang: $e");
          developer.log("Stack trace: $stackTrace");
        }
      } else if (fotoData == null) {
        developer.log('Both foto_barang and fotoBarang fields are null');
      }

      // Create the BarangModel
      final barang = BarangModel(
        idBarang: json['id_barang'] ?? 0,
        idKategori: json['id_kategori'] ?? 0,
        idPenitipan: json['id_penitipan'] ?? 0,
        namaBarang: json['nama_barang'] ?? '',
        deskripsi: json['deskripsi'] ?? '',
        harga: (json['harga'] ?? 0).toDouble(),
        masaGaransi: json['masa_garansi'],
        berat: json['berat'] ?? 0,
        rating: (json['rating'] ?? 0).toDouble(),
        statusBarang: json['status_barang'] ?? 'Tersedia',
        kategori: kategoriData,
        penitipanBarang:
            json['penitipan_barang'] != null
                ? PenitipanBarangModel.fromJson(json['penitipan_barang'])
                : null,
        fotoBarang: fotoData,
        detailTransaksi:
            json['detail_transaksi'] != null
                ? DetailTransaksiModel.fromJson(json['detail_transaksi'])
                : null,
        alokasiDonasi:
            json['alokasi_donasi'] != null
                ? AlokasiDonasiModel.fromJson(json['alokasi_donasi'])
                : null,
      );

      // Log the created model
      developer.log('\n=== Created BarangModel ===');
      developer.log('ID: ${barang.idBarang}');
      developer.log('Nama: ${barang.namaBarang}');
      developer.log('Foto count: ${barang.fotoBarang?.length ?? 0}');
      if (barang.fotoBarang != null) {
        for (var foto in barang.fotoBarang!) {
          developer.log(
            '- Foto: ID=${foto.idFotoBarang}, URL=${foto.urlFoto}, Thumbnail=${foto.isThumbnail}',
          );
        }
      }

      return barang;
    } catch (e, stackTrace) {
      developer.log("\n=== CRITICAL ERROR in BarangModel.fromJson ===");
      developer.log("Error: $e");
      developer.log("Stack trace: $stackTrace");
      developer.log("Raw JSON that caused error:");
      developer.log(JsonEncoder.withIndent('  ').convert(json));

      // Return model minimal untuk hindari crash aplikasi
      return BarangModel(
        idBarang: json['id_barang'] ?? 0,
        idKategori: json['id_kategori'] ?? 0,
        idPenitipan: json['id_penitipan'] ?? 0,
        namaBarang:
            json['nama_barang'] ?? 'Error: ${e.toString().substring(0, 20)}...',
        deskripsi: 'Error saat parsing data',
        harga: 0,
        statusBarang: 'Error',
        berat: 0,
        rating: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
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

    if (kategori != null) {
      data['kategori'] = kategori!.toJson();
    }
    if (penitipanBarang != null) {
      data['penitipan_barang'] = penitipanBarang!.toJson();
    }
    if (alokasiDonasi != null) {
      data['alokasi_donasi'] = alokasiDonasi!.toJson();
    }
    if (detailTransaksi != null) {
      data['detail_transaksi'] = detailTransaksi!.toJson();
    }

    return data;
  }

  BarangModel copyWith({
    int? idBarang,
    int? idKategori,
    int? idPenitipan,
    String? namaBarang,
    String? deskripsi,
    double? harga,
    String? masaGaransi,
    int? berat,
    double? rating,
    String? statusBarang,
    KategoriBarangModel? kategori,
    PenitipanBarangModel? penitipanBarang,
    List<FotoBarangModel>? fotoBarang,
    DetailTransaksiModel? detailTransaksi,
    AlokasiDonasiModel? alokasiDonasi,
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
      detailTransaksi: detailTransaksi ?? this.detailTransaksi,
      alokasiDonasi: alokasiDonasi ?? this.alokasiDonasi,
    );
  }
}
