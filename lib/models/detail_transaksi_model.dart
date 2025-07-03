import 'barang_model.dart';
import 'transaksi_model.dart';
import 'dart:developer' as developer;

class DetailTransaksiModel {
  final int idDetailTransaksi;
  final int idBarang;
  final int idTransaksi;
  final double hargaItem;
  final BarangModel? barang;
  final TransaksiModel? transaksi;

  DetailTransaksiModel({
    required this.idDetailTransaksi,
    required this.idBarang,
    required this.idTransaksi,
    required this.hargaItem,
    this.barang,
    this.transaksi,
  });

  factory DetailTransaksiModel.fromJson(Map<String, dynamic> json) {
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

      // Parse barang dan transaksi dengan error handling
      BarangModel? barangData;
      if (json['barang'] != null) {
        try {
          barangData = BarangModel.fromJson(json['barang']);
        } catch (e) {
          developer.log('Error parsing barang in detail_transaksi: $e');
        }
      }

      TransaksiModel? transaksiData;
      if (json['transaksi'] != null) {
        try {
          transaksiData = TransaksiModel.fromJson(json['transaksi']);
        } catch (e) {
          developer.log('Error parsing transaksi in detail_transaksi: $e');
        }
      }

      return DetailTransaksiModel(
        idDetailTransaksi: parseIntValue(json['id_detail_transaksi']),
        idBarang: parseIntValue(json['id_barang']),
        idTransaksi: parseIntValue(json['id_transaksi']),
        hargaItem: parseDoubleValue(json['harga_item']),
        barang: barangData,
        transaksi: transaksiData,
      );
    } catch (e) {
      developer.log('Error parsing DetailTransaksiModel: $e');
      developer.log('Raw JSON: $json');

      // Return default model untuk hindari crash
      return DetailTransaksiModel(
        idDetailTransaksi: 0,
        idBarang: 0,
        idTransaksi: 0,
        hargaItem: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id_detail_transaksi': idDetailTransaksi,
      'id_barang': idBarang,
      'id_transaksi': idTransaksi,
      'harga_item': hargaItem,
    };
    if (barang != null) {
      data['barang'] = barang!.toJson();
    }
    if (transaksi != null) {
      data['transaksi'] = transaksi!.toJson();
    }
    return data;
  }

  String get hargaItemFormatted {
    return formatRupiah(hargaItem);
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
}
