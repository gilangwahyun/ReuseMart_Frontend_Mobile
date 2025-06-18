import 'barang_model.dart';
import 'transaksi_model.dart';

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
    return DetailTransaksiModel(
      idDetailTransaksi: json['id_detail_transaksi'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      idTransaksi: json['id_transaksi'] ?? 0,
      hargaItem: (json['harga_item'] ?? 0).toDouble(),
      barang:
          json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
      transaksi:
          json['transaksi'] != null
              ? TransaksiModel.fromJson(json['transaksi'])
              : null,
    );
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
