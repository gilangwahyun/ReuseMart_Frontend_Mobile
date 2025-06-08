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
    try {
      // Cek jika kita mendapatkan barang, untuk mencegah infinite recursion
      BarangModel? barangData;
      if (json['barang'] != null) {
        try {
          // Hati-hati untuk mencegah infinite recursion
          // Tambahkan flag khusus ke json untuk mencegah parsing detail_transaksi lagi
          Map<String, dynamic> barangJson = Map<String, dynamic>.from(
            json['barang'],
          );
          // Hapus detail_transaksi dari barang untuk mencegah infinite recursion
          barangJson.remove('detail_transaksi');
          barangJson.remove('detailTransaksi');

          barangData = BarangModel.fromJson(barangJson);
        } catch (e) {
          print("Error parsing barang dalam DetailTransaksiModel: $e");
          print("Raw barang data: ${json['barang']}");
        }
      }

      // Parse transaksi jika tersedia
      TransaksiModel? transaksiData;
      if (json['transaksi'] != null) {
        try {
          transaksiData = TransaksiModel.fromJson(json['transaksi']);
        } catch (e) {
          print("Error parsing transaksi dalam DetailTransaksiModel: $e");
          print("Raw transaksi data: ${json['transaksi']}");
        }
      }

      return DetailTransaksiModel(
        idDetailTransaksi:
            int.tryParse(json['id_detail_transaksi']?.toString() ?? '0') ?? 0,
        idBarang: int.tryParse(json['id_barang']?.toString() ?? '0') ?? 0,
        idTransaksi: int.tryParse(json['id_transaksi']?.toString() ?? '0') ?? 0,
        hargaItem:
            json['harga_item'] != null
                ? double.tryParse(json['harga_item'].toString()) ?? 0.0
                : 0.0,
        barang: barangData,
        transaksi: transaksiData,
      );
    } catch (e) {
      print("ERROR parsing DetailTransaksiModel: $e");
      print("Raw JSON: $json");

      // Return default model untuk hindari aplikasi crash
      return DetailTransaksiModel(
        idDetailTransaksi: 0,
        idBarang: 0,
        idTransaksi: 0,
        hargaItem: 0.0,
      );
    }
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

  // Tambahkan method copyWith
  DetailTransaksiModel copyWith({
    int? idDetailTransaksi,
    int? idBarang,
    int? idTransaksi,
    double? hargaItem,
    BarangModel? barang,
    TransaksiModel? transaksi,
  }) {
    return DetailTransaksiModel(
      idDetailTransaksi: idDetailTransaksi ?? this.idDetailTransaksi,
      idBarang: idBarang ?? this.idBarang,
      idTransaksi: idTransaksi ?? this.idTransaksi,
      hargaItem: hargaItem ?? this.hargaItem,
      barang: barang ?? this.barang,
      transaksi: transaksi ?? this.transaksi,
    );
  }
}
