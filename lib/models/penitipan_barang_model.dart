import 'penitip_model.dart';
import 'pegawai_model.dart';
import 'barang_model.dart';

class PenitipanBarangModel {
  final int idPenitipan;
  final int idPenitip;
  final String tanggalAwalPenitipan;
  final String tanggalAkhirPenitipan;
  final String namaPetugasQc;
  final int? idPegawai;
  final PenitipModel? penitip;
  final PegawaiModel? pegawai;
  final List<BarangModel>? barang;

  PenitipanBarangModel({
    required this.idPenitipan,
    required this.idPenitip,
    required this.tanggalAwalPenitipan,
    required this.tanggalAkhirPenitipan,
    required this.namaPetugasQc,
    this.idPegawai,
    this.penitip,
    this.pegawai,
    this.barang,
  });

  factory PenitipanBarangModel.fromJson(Map<String, dynamic> json) {
    // Parse penitip jika tersedia
    PenitipModel? penitipData;
    if (json['penitip'] != null) {
      penitipData = PenitipModel.fromJson(json['penitip']);
    }

    // Parse pegawai jika tersedia
    PegawaiModel? pegawaiData;
    if (json['pegawai'] != null) {
      pegawaiData = PegawaiModel.fromJson(json['pegawai']);
    }

    // Parse barang jika tersedia
    List<BarangModel>? barangData;
    if (json['barang'] != null) {
      barangData =
          (json['barang'] as List)
              .map((item) => BarangModel.fromJson(item))
              .toList();
    } else if (json['barang_array'] != null) {
      // Alternatif nama field dari API
      barangData =
          (json['barang_array'] as List)
              .map((item) => BarangModel.fromJson(item))
              .toList();
    }

    return PenitipanBarangModel(
      idPenitipan: json['id_penitipan'],
      idPenitip: json['id_penitip'],
      tanggalAwalPenitipan: json['tanggal_awal_penitipan'],
      tanggalAkhirPenitipan: json['tanggal_akhir_penitipan'],
      namaPetugasQc: json['nama_petugas_qc'],
      idPegawai: json['id_pegawai'],
      penitip: penitipData,
      pegawai: pegawaiData,
      barang: barangData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id_penitipan': idPenitipan,
      'id_penitip': idPenitip,
      'tanggal_awal_penitipan': tanggalAwalPenitipan,
      'tanggal_akhir_penitipan': tanggalAkhirPenitipan,
      'nama_petugas_qc': namaPetugasQc,
    };

    if (idPegawai != null) {
      data['id_pegawai'] = idPegawai;
    }

    return data;
  }
}
