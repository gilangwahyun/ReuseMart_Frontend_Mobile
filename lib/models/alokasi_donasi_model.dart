import 'request_donasi_model.dart';
import 'barang_model.dart';

class AlokasiDonasiModel {
  final int idAlokasiDonasi;
  final int idRequestDonasi;
  final int idBarang;
  final String? tanggalDonasi;
  final String? namaPenerima;
  final RequestDonasiModel? requestDonasi;
  final BarangModel? barang;

  AlokasiDonasiModel({
    required this.idAlokasiDonasi,
    required this.idRequestDonasi,
    required this.idBarang,
    this.tanggalDonasi,
    this.namaPenerima,
    this.requestDonasi,
    this.barang,
  });

  factory AlokasiDonasiModel.fromJson(Map<String, dynamic> json) {
    return AlokasiDonasiModel(
      idAlokasiDonasi: json['id_alokasi_donasi'] ?? 0,
      idRequestDonasi: json['id_request_donasi'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      tanggalDonasi: json['tanggal_donasi'],
      namaPenerima: json['nama_penerima'],
      requestDonasi:
          json['request_donasi'] != null
              ? RequestDonasiModel.fromJson(json['request_donasi'])
              : (json['requestDonasi'] != null
                  ? RequestDonasiModel.fromJson(json['requestDonasi'])
                  : null),
      barang:
          json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_alokasi_donasi': idAlokasiDonasi,
      'id_request_donasi': idRequestDonasi,
      'id_barang': idBarang,
      'tanggal_donasi': tanggalDonasi,
      'nama_penerima': namaPenerima,
    };
  }
}
