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
    print('\n=== DEBUG: FotoBarangModel.fromJson ===');
    print('Raw JSON: $json');

    // Ambil URL dari response dan pastikan formatnya benar
    String urlFoto = json['url_foto'] ?? '';

    // Pastikan URL tidak memiliki leading slash
    if (urlFoto.startsWith('/')) {
      urlFoto = urlFoto.substring(1);
    }

    // Pastikan URL menggunakan format yang konsisten
    if (!urlFoto.startsWith('storage/')) {
      urlFoto = 'storage/$urlFoto';
    }

    bool isThumbnail =
        json['is_thumbnail'] == 1 || json['is_thumbnail'] == true;

    print('Parsed values:');
    print('- ID Foto: ${json['id_foto_barang']}');
    print('- ID Barang: ${json['id_barang']}');
    print('- URL Foto: $urlFoto');
    print('- Is Thumbnail: $isThumbnail (raw value: ${json['is_thumbnail']})');

    return FotoBarangModel(
      idFotoBarang: json['id_foto_barang'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      urlFoto: urlFoto,
      isThumbnail: isThumbnail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_foto_barang': idFotoBarang,
      'id_barang': idBarang,
      'url_foto': urlFoto,
      'is_thumbnail': isThumbnail ? 1 : 0,
    };
  }
}
