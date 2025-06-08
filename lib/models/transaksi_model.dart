import 'pembeli_model.dart';

class TransaksiModel {
  final int idTransaksi;
  final int idPembeli;
  final int idAlamat;
  final double? totalHarga;
  final String statusTransaksi;
  final String metodePengiriman;
  final String tanggalTransaksi;
  final PembeliModel? pembeli;

  TransaksiModel({
    required this.idTransaksi,
    required this.idPembeli,
    required this.idAlamat,
    this.totalHarga,
    required this.statusTransaksi,
    required this.metodePengiriman,
    required this.tanggalTransaksi,
    this.pembeli,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    try {
      return TransaksiModel(
        idTransaksi: json['id_transaksi'] ?? 0,
        idPembeli: json['id_pembeli'] ?? 0,
        idAlamat: json['id_alamat'] ?? 0,
        totalHarga: json['total_harga']?.toDouble(),
        statusTransaksi: json['status_transaksi'] ?? 'Menunggu Pembayaran',
        metodePengiriman: json['metode_pengiriman'] ?? 'Ambil Sendiri',
        tanggalTransaksi:
            json['tanggal_transaksi'] ?? DateTime.now().toIso8601String(),
        pembeli:
            json['pembeli'] != null
                ? PembeliModel.fromJson(json['pembeli'])
                : null,
      );
    } catch (e) {
      print('Error parsing TransaksiModel: $e');
      print('Raw JSON: $json');
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
    );
  }
}
