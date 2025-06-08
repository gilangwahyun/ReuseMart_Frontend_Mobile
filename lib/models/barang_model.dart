import 'kategori_barang_model.dart';
import 'penitipan_barang_model.dart';
import 'foto_barang_model.dart';
import 'detail_transaksi_model.dart';
import 'alokasi_donasi_model.dart';
import 'transaksi_model.dart';
import 'penitip_model.dart';
import 'pegawai_model.dart';
import 'dart:developer' as developer;

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
  final DetailTransaksiModel? detailTransaksi;
  final AlokasiDonasiModel? alokasiDonasi;

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
    this.detailTransaksi,
    this.alokasiDonasi,
  });

  String get gambarUtama {
    if (fotoBarang != null && fotoBarang!.isNotEmpty) {
      try {
        // Cari foto yang bertanda utama (is_thumbnail)
        final thumbnailFoto = fotoBarang!.firstWhere(
          (foto) => foto.isThumbnail == true,
          orElse: () => fotoBarang!.first,
        );
        return thumbnailFoto.urlFoto;
      } catch (e) {
        print("Error mengambil gambar utama: $e");
      }
    }
    return '';
  }

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('=== DEBUG: Parsing BarangModel from JSON ===');
      developer.log('Barang ID: ${json['id_barang']}');
      developer.log('Raw JSON: $json');

      // Parse kategori jika tersedia
      KategoriBarangModel? kategoriData;
      if (json['kategori'] != null) {
        try {
          developer.log('Parsing kategori data...');
          kategoriData = KategoriBarangModel.fromJson(json['kategori']);
          developer.log('Kategori parsed successfully');
        } catch (e) {
          developer.log('Error parsing kategori: $e');
        }
      }

      // Parse penitipan barang dengan logging detail
      PenitipanBarangModel? penitipanData;
      if (json['penitipan_barang'] != null) {
        try {
          developer.log(
            '=== DEBUG: Parsing penitipan_barang in BarangModel ===',
          );
          developer.log(
            'Raw penitipan_barang data: ${json['penitipan_barang']}',
          );

          final penitipanJson = json['penitipan_barang'];

          // Log setiap field yang akan digunakan
          developer.log('Individual fields from penitipan_barang:');
          developer.log(
            'id_penitipan: ${penitipanJson['id_penitipan']} (${penitipanJson['id_penitipan']?.runtimeType})',
          );
          developer.log(
            'id_penitip: ${penitipanJson['id_penitip']} (${penitipanJson['id_penitip']?.runtimeType})',
          );
          developer.log(
            'tanggal_awal_penitipan: ${penitipanJson['tanggal_awal_penitipan']} (${penitipanJson['tanggal_awal_penitipan']?.runtimeType})',
          );
          developer.log(
            'tanggal_akhir_penitipan: ${penitipanJson['tanggal_akhir_penitipan']} (${penitipanJson['tanggal_akhir_penitipan']?.runtimeType})',
          );
          developer.log(
            'nama_petugas_qc: ${penitipanJson['nama_petugas_qc']} (${penitipanJson['nama_petugas_qc']?.runtimeType})',
          );

          penitipanData = PenitipanBarangModel.fromJson(penitipanJson);

          developer.log('Penitipan data created successfully:');
          developer.log(
            'tanggalAwalPenitipan: ${penitipanData.tanggalAwalPenitipan}',
          );
          developer.log(
            'tanggalAkhirPenitipan: ${penitipanData.tanggalAkhirPenitipan}',
          );
          developer.log('namaPetugasQc: ${penitipanData.namaPetugasQc}');
        } catch (e, stackTrace) {
          developer.log('Error parsing penitipan_barang: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      // Fallback untuk penitipanBarang jika belum berhasil di-parse
      if (penitipanData == null && json['penitipanBarang'] != null) {
        try {
          developer.log(
            'Attempting to parse penitipanBarang alternative field...',
          );
          final penitipanJson = json['penitipanBarang'];
          developer.log('Raw penitipanBarang data: $penitipanJson');
          penitipanData = PenitipanBarangModel.fromJson(penitipanJson);
          developer.log('Successfully parsed penitipanBarang alternative');
        } catch (e, stackTrace) {
          developer.log('Error parsing penitipanBarang alternative: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      // Fallback terakhir: buat model penitipan dasar jika masih null
      if (penitipanData == null && json['id_penitipan'] != null) {
        try {
          developer.log('Creating basic penitipan model from barang data...');
          developer.log('Using fields:');
          developer.log('id_penitipan: ${json['id_penitipan']}');
          developer.log(
            'tanggal_awal_penitipan: ${json['tanggal_awal_penitipan']}',
          );
          developer.log(
            'tanggal_akhir_penitipan: ${json['tanggal_akhir_penitipan']}',
          );
          developer.log('nama_petugas_qc: ${json['nama_petugas_qc']}');

          penitipanData = PenitipanBarangModel(
            idPenitipan: json['id_penitipan'] ?? 0,
            idPenitip: json['id_penitip'] ?? 0,
            tanggalAwalPenitipan: json['tanggal_awal_penitipan']?.toString(),
            tanggalAkhirPenitipan: json['tanggal_akhir_penitipan']?.toString(),
            namaPetugasQc: json['nama_petugas_qc']?.toString(),
            idPegawai: json['id_pegawai'],
          );
          developer.log('Successfully created basic penitipan model');
        } catch (e, stackTrace) {
          developer.log('CRITICAL: Failed to create basic penitipan model: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      // Parse foto barang jika tersedia
      List<FotoBarangModel>? fotoData;
      if (json['foto_barang'] != null) {
        try {
          fotoData =
              (json['foto_barang'] as List)
                  .map((item) => FotoBarangModel.fromJson(item))
                  .toList();
        } catch (e) {
          print("Error parsing foto_barang: $e");
        }
      } else if (json['fotoBarang'] != null) {
        try {
          fotoData =
              (json['fotoBarang'] as List)
                  .map((item) => FotoBarangModel.fromJson(item))
                  .toList();
        } catch (e) {
          print("Error parsing fotoBarang: $e");
        }
      }

      // Parse detail transaksi jika tersedia
      DetailTransaksiModel? detailTransaksiData;
      if (json['detail_transaksi'] != null) {
        try {
          detailTransaksiData = DetailTransaksiModel.fromJson(
            json['detail_transaksi'],
          );
        } catch (e) {
          print("Error parsing detail_transaksi: $e");
        }
      } else if (json['detailTransaksi'] != null) {
        try {
          detailTransaksiData = DetailTransaksiModel.fromJson(
            json['detailTransaksi'],
          );
        } catch (e) {
          print("Error parsing detailTransaksi: $e");
        }
      }

      // Handling khusus untuk barang dengan status 'Habis'
      if (detailTransaksiData == null && json['status_barang'] == 'Habis') {
        // Jika barang habis (terjual) tapi detailTransaksi kosong

        // Mencoba mencari field lain di JSON yang mungkin berisi data transaksi
        if (json.containsKey('transaksi') && json['transaksi'] != null) {
          try {
            var transaksiData = json['transaksi'];
            // Buat dummy detailTransaksi
            detailTransaksiData = DetailTransaksiModel(
              idDetailTransaksi: 0,
              idBarang: json['id_barang'],
              idTransaksi: transaksiData['id_transaksi'] ?? 0,
              hargaItem: double.tryParse(json['harga'].toString()) ?? 0,
              transaksi: TransaksiModel.fromJson(transaksiData),
            );
          } catch (e) {
            print("Error membuat dummy detailTransaksi: $e");
          }
        }
      }

      // Parse alokasi donasi jika tersedia
      AlokasiDonasiModel? alokasiDonasiData;
      if (json['alokasi_donasi'] != null) {
        try {
          alokasiDonasiData = AlokasiDonasiModel.fromJson(
            json['alokasi_donasi'],
          );
        } catch (e) {
          print("Error parsing alokasi_donasi: $e");
        }
      } else if (json['alokasiDonasi'] != null) {
        try {
          alokasiDonasiData = AlokasiDonasiModel.fromJson(
            json['alokasiDonasi'],
          );
        } catch (e) {
          print("Error parsing alokasiDonasi: $e");
        }
      }

      return BarangModel(
        idBarang: json['id_barang'] ?? 0,
        idKategori: json['id_kategori'] ?? 0,
        idPenitipan: json['id_penitipan'] ?? 0,
        namaBarang: json['nama_barang'] ?? '',
        deskripsi: json['deskripsi'],
        harga: double.tryParse(json['harga'].toString()) ?? 0,
        masaGaransi: json['masa_garansi'],
        berat:
            json['berat'] != null
                ? double.tryParse(json['berat'].toString())
                : null,
        rating:
            json['rating'] != null
                ? double.tryParse(json['rating'].toString())
                : null,
        statusBarang: json['status_barang'] ?? 'Tidak diketahui',
        kategori: kategoriData,
        penitipanBarang: penitipanData,
        fotoBarang: fotoData,
        detailTransaksi: detailTransaksiData,
        alokasiDonasi: alokasiDonasiData,
      );
    } catch (e, stackTrace) {
      developer.log("CRITICAL ERROR in BarangModel.fromJson: $e");
      developer.log("Stack trace: $stackTrace");
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
      );
    }
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
