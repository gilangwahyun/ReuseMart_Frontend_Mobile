import '../api/api_service.dart';
import 'dart:developer' as developer;

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
    developer.log('\n=== DEBUG: FotoBarangModel.fromJson ===');
    developer.log('Raw JSON: $json');

    // Fungsi helper untuk parsing ID
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Ambil URL dari response dan pastikan formatnya benar
    String urlFoto = json['url_foto'] ?? '';

    // Periksa berbagai format URL yang mungkin dikirim dari server
    developer.log('Original URL: $urlFoto');

    // Pastikan URL tidak memiliki leading slash
    if (urlFoto.startsWith('/')) {
      urlFoto = urlFoto.substring(1);
    }

    // Perbaikan untuk path foto yang tersimpan di Laravel public/images/barang
    if (urlFoto.contains('images/barang')) {
      // URL sudah dalam format yang benar, tidak perlu diubah
      developer.log(
        'URL berisi path images/barang, tetap menggunakan: $urlFoto',
      );
    } else if (urlFoto.contains('storage')) {
      // Jika menggunakan storage, pastikan formatnya benar
      if (!urlFoto.startsWith('storage/')) {
        urlFoto = 'storage/$urlFoto';
      }
      developer.log('URL berisi path storage, diformat menjadi: $urlFoto');
    } else if (urlFoto.isNotEmpty) {
      // Jika tidak ada path khusus, gunakan format images/barang
      urlFoto = 'images/barang/$urlFoto';
      developer.log('URL tanpa path, diasumsikan di images/barang: $urlFoto');
    }

    bool isThumbnail =
        json['is_thumbnail'] == 1 || json['is_thumbnail'] == true;

    developer.log('Parsed values:');
    developer.log('- ID Foto: ${json['id_foto_barang']}');
    developer.log('- ID Barang: ${json['id_barang']}');
    developer.log('- URL Foto (final): $urlFoto');
    developer.log(
      '- Is Thumbnail: $isThumbnail (raw value: ${json['is_thumbnail']})',
    );

    return FotoBarangModel(
      idFotoBarang: parseId(json['id_foto_barang']),
      idBarang: parseId(json['id_barang']),
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
