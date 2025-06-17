import 'penitip_model.dart';
import 'pegawai_model.dart';
import 'barang_model.dart';
import 'dart:developer' as developer;

class PenitipanBarangModel {
  final int idPenitipan;
  final int idPenitip;
  final String? tanggalAwalPenitipan;
  final String? tanggalAkhirPenitipan;
  final String? namaPetugasQc;
  final int? idPegawai;
  final PenitipModel? penitip;
  final PegawaiModel? pegawai;
  final List<BarangModel>? barang;

  PenitipanBarangModel({
    required this.idPenitipan,
    required this.idPenitip,
    this.tanggalAwalPenitipan,
    this.tanggalAkhirPenitipan,
    this.namaPetugasQc,
    this.idPegawai,
    this.penitip,
    this.pegawai,
    this.barang,
  });

  factory PenitipanBarangModel.fromJson(Map<String, dynamic> json) {
    print('=== DEBUG: Creating PenitipanBarangModel from JSON ===');
    print('Input JSON:');
    print(json);

    try {
      // Parse dates and handle null values
      String? tanggalAwal = json['tanggal_awal_penitipan']?.toString();
      String? tanggalAkhir = json['tanggal_akhir_penitipan']?.toString();
      String? namaPetugas = json['nama_petugas_qc']?.toString();

      print('=== DEBUG: Raw Values ===');
      print(
        'tanggal_awal_penitipan (raw): ${json['tanggal_awal_penitipan']} (${json['tanggal_awal_penitipan']?.runtimeType})',
      );
      print(
        'tanggal_akhir_penitipan (raw): ${json['tanggal_akhir_penitipan']} (${json['tanggal_akhir_penitipan']?.runtimeType})',
      );
      print(
        'nama_petugas_qc (raw): ${json['nama_petugas_qc']} (${json['nama_petugas_qc']?.runtimeType})',
      );

      // Handle empty strings and special values
      if (tanggalAwal?.isEmpty ?? true) tanggalAwal = null;
      if (tanggalAkhir?.isEmpty ?? true) tanggalAkhir = null;
      if (namaPetugas?.isEmpty ?? true) namaPetugas = null;

      // Handle "0000-00-00" dates
      if (tanggalAwal == "0000-00-00") tanggalAwal = null;
      if (tanggalAkhir == "0000-00-00") tanggalAkhir = null;

      print('=== DEBUG: Processed Values ===');
      print('tanggalAwal (processed): $tanggalAwal');
      print('tanggalAkhir (processed): $tanggalAkhir');
      print('namaPetugas (processed): $namaPetugas');

      // Parse related models with error handling
      PenitipModel? penitipData;
      if (json['penitip'] != null) {
        try {
          print('=== DEBUG: Parsing Penitip Data ===');
          print('Raw penitip data: ${json['penitip']}');
          penitipData = PenitipModel.fromJson(json['penitip']);
          print('Successfully parsed penitip data: ${penitipData.namaPenitip}');
        } catch (e, stackTrace) {
          print('Error parsing penitip data: $e');
          print('Stack trace: $stackTrace');
        }
      }

      PegawaiModel? pegawaiData;
      if (json['pegawai'] != null) {
        try {
          print('=== DEBUG: Parsing Pegawai Data ===');
          print('Raw pegawai data: ${json['pegawai']}');
          pegawaiData = PegawaiModel.fromJson(json['pegawai']);
          print('Successfully parsed pegawai data');
        } catch (e, stackTrace) {
          print('Error parsing pegawai data: $e');
          print('Stack trace: $stackTrace');
        }
      }

      List<BarangModel>? barangList;
      if (json['barang'] != null) {
        try {
          print('=== DEBUG: Parsing Barang List ===');
          print('Raw barang data: ${json['barang']}');
          barangList =
              (json['barang'] as List)
                  .map((item) => BarangModel.fromJson(item))
                  .toList();
          print('Successfully parsed ${barangList.length} barang items');
        } catch (e, stackTrace) {
          print('Error parsing barang list: $e');
          print('Stack trace: $stackTrace');
        }
      }

      // Create and return the model
      final model = PenitipanBarangModel(
        idPenitipan: json['id_penitipan'] ?? 0,
        idPenitip: json['id_penitip'] ?? 0,
        tanggalAwalPenitipan: tanggalAwal,
        tanggalAkhirPenitipan: tanggalAkhir,
        namaPetugasQc: namaPetugas,
        idPegawai: json['id_pegawai'],
        penitip: penitipData,
        pegawai: pegawaiData,
        barang: barangList,
      );

      print('=== DEBUG: Created PenitipanBarangModel ===');
      print('idPenitipan: ${model.idPenitipan}');
      print('tanggalAwalPenitipan: ${model.tanggalAwalPenitipan}');
      print('tanggalAkhirPenitipan: ${model.tanggalAkhirPenitipan}');
      print('namaPetugasQc: ${model.namaPetugasQc}');

      return model;
    } catch (e, stackTrace) {
      print('=== ERROR: Failed to create PenitipanBarangModel ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penitipan': idPenitipan,
      'id_penitip': idPenitip,
      'tanggal_awal_penitipan': tanggalAwalPenitipan,
      'tanggal_akhir_penitipan': tanggalAkhirPenitipan,
      'nama_petugas_qc': namaPetugasQc,
      'id_pegawai': idPegawai,
      'penitip': penitip?.toJson(),
      'pegawai': pegawai?.toJson(),
      'barang': barang?.map((x) => x.toJson()).toList(),
    };
  }
}
