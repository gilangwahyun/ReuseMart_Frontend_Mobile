import 'pembeli_model.dart';
import 'detail_transaksi_model.dart';
import 'dart:developer' as developer;

class TransaksiModel {
  final int idTransaksi;
  final int idPembeli;
  final int idAlamat;
  final double? totalHarga;
  final String statusTransaksi;
  final String metodePengiriman;
  final String tanggalTransaksi;
  final PembeliModel? pembeli;
  final List<DetailTransaksiModel> detailTransaksi;

  TransaksiModel({
    required this.idTransaksi,
    required this.idPembeli,
    required this.idAlamat,
    this.totalHarga,
    required this.statusTransaksi,
    required this.metodePengiriman,
    required this.tanggalTransaksi,
    this.pembeli,
    this.detailTransaksi = const [],
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper functions untuk parsing nilai yang mungkin string
      int parseIntValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      double parseDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Parse detail transaksi jika ada
      List<DetailTransaksiModel> detailList = [];
      if (json['detail_transaksi'] != null) {
        try {
          detailList =
              (json['detail_transaksi'] as List)
                  .map((item) => DetailTransaksiModel.fromJson(item))
                  .toList();
        } catch (e) {
          developer.log('Error parsing detail_transaksi: $e');
        }
      }

      return TransaksiModel(
        idTransaksi: parseIntValue(json['id_transaksi']),
        idPembeli: parseIntValue(json['id_pembeli']),
        idAlamat: parseIntValue(json['id_alamat']),
        totalHarga: parseDoubleValue(json['total_harga']),
        statusTransaksi: json['status_transaksi'] ?? 'Menunggu Pembayaran',
        metodePengiriman: json['metode_pengiriman'] ?? 'Ambil Sendiri',
        tanggalTransaksi:
            json['tanggal_transaksi'] ?? DateTime.now().toIso8601String(),
        pembeli:
            json['pembeli'] != null
                ? PembeliModel.fromJson(json['pembeli'])
                : null,
        detailTransaksi: detailList,
      );
    } catch (e) {
      developer.log('Error parsing TransaksiModel: $e');
      developer.log('Raw JSON: $json');
      // Return default model untuk hindari aplikasi crash
      return TransaksiModel(
        idTransaksi: 0,
        idPembeli: 0,
        idAlamat: 0,
        totalHarga: 0,
        statusTransaksi: 'Error',
        metodePengiriman: 'Error',
        tanggalTransaksi: DateTime.now().toIso8601String(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_transaksi'] = idTransaksi;
    data['id_pembeli'] = idPembeli;
    data['id_alamat'] = idAlamat;
    data['total_harga'] = totalHarga;
    data['status_transaksi'] = statusTransaksi;
    data['metode_pengiriman'] = metodePengiriman;
    data['tanggal_transaksi'] = tanggalTransaksi;
    if (pembeli != null) {
      data['pembeli'] = pembeli!.toJson();
    }
    data['detail_transaksi'] =
        detailTransaksi.map((detail) => detail.toJson()).toList();
    return data;
  }

  // Helper untuk format tanggal
  String get tanggalFormatted {
    try {
      final date = DateTime.parse(tanggalTransaksi);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return tanggalTransaksi;
    }
  }

  // Helper untuk format harga ke rupiah
  String get totalHargaFormatted {
    return formatRupiah(totalHarga ?? 0.0);
  }

  String formatRupiah(double price) {
    int priceInt = price.toInt();
    String priceStr = priceInt.toString();
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = priceStr[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }

    return result;
  }

  // Method copyWith
  TransaksiModel copyWith({
    int? idTransaksi,
    int? idPembeli,
    int? idAlamat,
    double? totalHarga,
    String? statusTransaksi,
    String? metodePengiriman,
    String? tanggalTransaksi,
    PembeliModel? pembeli,
    List<DetailTransaksiModel>? detailTransaksi,
  }) {
    return TransaksiModel(
      idTransaksi: idTransaksi ?? this.idTransaksi,
      idPembeli: idPembeli ?? this.idPembeli,
      idAlamat: idAlamat ?? this.idAlamat,
      totalHarga: totalHarga ?? this.totalHarga,
      statusTransaksi: statusTransaksi ?? this.statusTransaksi,
      metodePengiriman: metodePengiriman ?? this.metodePengiriman,
      tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
      pembeli: pembeli ?? this.pembeli,
      detailTransaksi: detailTransaksi ?? this.detailTransaksi,
    );
  }
}
