class TransaksiModel {
  final int idTransaksi;
  final int idPembeli;
  final int? idAlamat;
  final double totalHarga;
  final String statusTransaksi;
  final String? metodePengiriman;
  final DateTime tanggalTransaksi;

  TransaksiModel({
    required this.idTransaksi,
    required this.idPembeli,
    this.idAlamat,
    required this.totalHarga,
    required this.statusTransaksi,
    this.metodePengiriman,
    required this.tanggalTransaksi,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      idTransaksi: json['id_transaksi'] ?? 0,
      idPembeli: json['id_pembeli'] ?? 0,
      idAlamat: json['id_alamat'],
      totalHarga:
          json['total_harga'] != null
              ? double.parse(json['total_harga'].toString())
              : 0.0,
      statusTransaksi: json['status_transaksi'] ?? '',
      metodePengiriman: json['metode_pengiriman'],
      tanggalTransaksi:
          json['tanggal_transaksi'] != null
              ? DateTime.parse(json['tanggal_transaksi'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': idTransaksi,
      'id_pembeli': idPembeli,
      'id_alamat': idAlamat,
      'total_harga': totalHarga,
      'status_transaksi': statusTransaksi,
      'metode_pengiriman': metodePengiriman,
      'tanggal_transaksi': tanggalTransaksi.toIso8601String(),
    };
  }

  // Helper untuk format tanggal ke string
  String get tanggalFormatted {
    return '${tanggalTransaksi.day}-${tanggalTransaksi.month}-${tanggalTransaksi.year}';
  }

  // Helper untuk format harga ke rupiah
  String get totalHargaFormatted {
    return formatRupiah(totalHarga);
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
