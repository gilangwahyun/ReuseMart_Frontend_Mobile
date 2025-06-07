import 'merchandise_model.dart';

class KlaimMerchandise {
  final int idKlaim;
  final int idPembeli;
  final int idMerchandise;
  final int totalPoin;
  final String statusKlaim;
  final String? tanggalKlaim;
  final Merchandise? merchandise; // Optional for when we get it from relationship

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
    return KlaimMerchandise(
      idKlaim: json['id_klaim'],
      idPembeli: json['id_pembeli'],
      idMerchandise: json['id_merchandise'],
      totalPoin: json['total_poin'],
      statusKlaim: json['status_klaim'],
      tanggalKlaim: json['tanggal_klaim'],
      merchandise: json['merchandise'] != null
          ? Merchandise.fromJson(json['merchandise'])
          : null,
    );
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