import 'barang_model.dart';

class DetailTransaksiModel {
  final int idDetailTransaksi;
  final int idBarang;
  final int idTransaksi;
  final double hargaItem;
  final BarangModel? barang;

  DetailTransaksiModel({
    required this.idDetailTransaksi,
    required this.idBarang,
    required this.idTransaksi,
    required this.hargaItem,
    this.barang,
  });

  factory DetailTransaksiModel.fromJson(Map<String, dynamic> json) {
    return DetailTransaksiModel(
      idDetailTransaksi: json['id_detail_transaksi'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      idTransaksi: json['id_transaksi'] ?? 0,
      hargaItem:
          json['harga_item'] != null
              ? double.parse(json['harga_item'].toString())
              : 0.0,
      barang:
          json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_detail_transaksi': idDetailTransaksi,
      'id_barang': idBarang,
      'id_transaksi': idTransaksi,
      'harga_item': hargaItem,
    };
  }

  // Helper untuk format harga ke rupiah
  String get hargaItemFormatted {
    return formatRupiah(hargaItem);
  }

  // Format angka ke Rupiah
  static String formatRupiah(double amount) {
    String priceStr = amount.toStringAsFixed(0);
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
