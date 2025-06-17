class Merchandise {
  final int idMerchandise;
  final String namaMerchandise;
  final int jumlahPoin;
  final int stok;

  Merchandise({
    required this.idMerchandise,
    required this.namaMerchandise,
    required this.jumlahPoin,
    required this.stok,
  });

  factory Merchandise.fromJson(Map<String, dynamic> json) {
    return Merchandise(
      idMerchandise: json['id_merchandise'],
      namaMerchandise: json['nama_merchandise'],
      jumlahPoin: json['jumlah_poin'],
      stok: json['stok'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_merchandise': idMerchandise,
      'nama_merchandise': namaMerchandise,
      'jumlah_poin': jumlahPoin,
      'stok': stok,
    };
  }
} 