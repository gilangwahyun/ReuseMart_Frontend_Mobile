import 'dart:developer' as developer;

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
    try {
      // Helper functions untuk parsing nilai numerik
      int parseIntValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          final result = int.tryParse(value);
          if (result == null) {
            developer.log(
              'WARNING: Failed to parse "$value" as int, defaulting to 0',
            );
            return 0;
          }
          return result;
        }
        return 0;
      }

      final idMerchandise = parseIntValue(json['id_merchandise']);
      final jumlahPoin = parseIntValue(json['jumlah_poin']);
      final stok = parseIntValue(json['stok']);

      developer.log(
        'Parsing merchandise: ID=$idMerchandise, poin=$jumlahPoin, stok=$stok',
      );

      return Merchandise(
        idMerchandise: idMerchandise,
        namaMerchandise: json['nama_merchandise'] ?? '',
        jumlahPoin: jumlahPoin,
        stok: stok,
      );
    } catch (e) {
      developer.log('Error parsing Merchandise: $e');
      developer.log('JSON data: $json');

      // Return default model untuk mencegah crash
      return Merchandise(
        idMerchandise: 0,
        namaMerchandise: 'Error',
        jumlahPoin: 0,
        stok: 0,
      );
    }
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
