import 'organisasi_model.dart';

class RequestDonasiModel {
  final int idRequestDonasi;
  final int idOrganisasi;
  final String deskripsi;
  final String statusPengajuan;
  final String? tanggalPengajuan;
  final OrganisasiModel? organisasi;

  RequestDonasiModel({
    required this.idRequestDonasi,
    required this.idOrganisasi,
    required this.deskripsi,
    required this.statusPengajuan,
    this.tanggalPengajuan,
    this.organisasi,
  });

  factory RequestDonasiModel.fromJson(Map<String, dynamic> json) {
    return RequestDonasiModel(
      idRequestDonasi: json['id_request_donasi'] ?? 0,
      idOrganisasi: json['id_organisasi'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      statusPengajuan: json['status_pengajuan'] ?? '',
      tanggalPengajuan: json['tanggal_pengajuan'],
      organisasi:
          json['organisasi'] != null
              ? OrganisasiModel.fromJson(json['organisasi'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_request_donasi': idRequestDonasi,
      'id_organisasi': idOrganisasi,
      'deskripsi': deskripsi,
      'status_pengajuan': statusPengajuan,
      'tanggal_pengajuan': tanggalPengajuan,
    };
  }
}
