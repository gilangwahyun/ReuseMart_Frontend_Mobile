import 'merchandise_model.dart';
import 'dart:developer' as developer;

class KlaimMerchandise {
  final int idKlaim;
  final int idPembeli;
  final int idMerchandise;
  final int totalPoin;
  final String statusKlaim;
  final String? tanggalKlaim;
  final Merchandise?
  merchandise; // Optional for when we get it from relationship

  KlaimMerchandise({
    required this.idKlaim,
    required this.idPembeli,
    required this.idMerchandise,
    required this.totalPoin,
    required this.statusKlaim,
    this.tanggalKlaim,
    this.merchandise,
  });

  factory KlaimMerchandise.fromJson(Map<String, dynamic> json) {
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

      // Parse merchandise jika ada
      Merchandise? merchandiseObj;
      if (json['merchandise'] != null) {
        try {
          merchandiseObj = Merchandise.fromJson(json['merchandise']);
        } catch (e) {
          developer.log('Error parsing merchandise in klaim: $e');
        }
      }

      final idKlaim = parseIntValue(json['id_klaim']);
      final idPembeli = parseIntValue(json['id_pembeli']);
      final idMerchandise = parseIntValue(json['id_merchandise']);
      final totalPoin = parseIntValue(json['total_poin']);

      developer.log(
        'Parsed klaim: ID=$idKlaim, pembeli=$idPembeli, merchandise=$idMerchandise, poin=$totalPoin',
      );

      return KlaimMerchandise(
        idKlaim: idKlaim,
        idPembeli: idPembeli,
        idMerchandise: idMerchandise,
        totalPoin: totalPoin,
        statusKlaim: json['status_klaim'] ?? 'pending',
        tanggalKlaim: json['tanggal_klaim'],
        merchandise: merchandiseObj,
      );
    } catch (e) {
      developer.log('Error parsing KlaimMerchandise: $e');
      developer.log('JSON data: $json');

      // Return default model untuk mencegah crash
      return KlaimMerchandise(
        idKlaim: 0,
        idPembeli: 0,
        idMerchandise: 0,
        totalPoin: 0,
        statusKlaim: 'error',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_klaim': idKlaim,
      'id_pembeli': idPembeli,
      'id_merchandise': idMerchandise,
      'total_poin': totalPoin,
      'status_klaim': statusKlaim,
      'tanggal_klaim': tanggalKlaim,
    };
  }
}
