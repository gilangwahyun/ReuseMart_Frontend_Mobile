import '../api/api_service.dart';

class FotoBarangModel {
  final int idFotoBarang;
  final int idBarang;
  final String urlFoto;
  final bool isThumbnail;

  FotoBarangModel({
    required this.idFotoBarang,
    required this.idBarang,
    required this.urlFoto,
    required this.isThumbnail,
  });

  factory FotoBarangModel.fromJson(Map<String, dynamic> json) {
    // Ambil URL dari response
    String urlFoto = json['url_foto'] ?? '';

    // Debug: cetak URL asli
    print('URL foto asli dari server: $urlFoto');

    // Jangan tambahkan http:// karena ini akan ditambahkan di widget Image.network
    // Aplikasi mobile akan langsung memuat dari folder storage di server

    return FotoBarangModel(
      idFotoBarang: json['id_foto_barang'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      urlFoto: urlFoto, // Gunakan URL asli dari server
      isThumbnail: json['is_thumbnail'] == 1 || json['is_thumbnail'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    // Untuk simplisitas, gunakan URL asli saat mengirim ke server
    return {
      'id_foto_barang': idFotoBarang,
      'id_barang': idBarang,
      'url_foto': urlFoto,
      'is_thumbnail': isThumbnail ? 1 : 0,
    };
  }
}
