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
    developer.log('=== DEBUG: Creating PenitipanBarangModel from JSON ===');
    developer.log('Input JSON:');
    developer.log('$json');

    try {
      // Helper functions untuk parsing nilai yang mungkin string
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

      // Parse dates and handle null values
      String? tanggalAwal = json['tanggal_awal_penitipan']?.toString();
      String? tanggalAkhir = json['tanggal_akhir_penitipan']?.toString();
      String? namaPetugas = json['nama_petugas_qc']?.toString();

      developer.log('=== DEBUG: Raw Values ===');
      developer.log(
        'tanggal_awal_penitipan (raw): ${json['tanggal_awal_penitipan']} (${json['tanggal_awal_penitipan']?.runtimeType})',
      );
      developer.log(
        'tanggal_akhir_penitipan (raw): ${json['tanggal_akhir_penitipan']} (${json['tanggal_akhir_penitipan']?.runtimeType})',
      );
      developer.log(
        'nama_petugas_qc (raw): ${json['nama_petugas_qc']} (${json['nama_petugas_qc']?.runtimeType})',
      );

      // Handle empty strings and special values
      if (tanggalAwal?.isEmpty ?? true) tanggalAwal = null;
      if (tanggalAkhir?.isEmpty ?? true) tanggalAkhir = null;
      if (namaPetugas?.isEmpty ?? true) namaPetugas = null;

      // Handle "0000-00-00" dates
      if (tanggalAwal == "0000-00-00") tanggalAwal = null;
      if (tanggalAkhir == "0000-00-00") tanggalAkhir = null;

      developer.log('=== DEBUG: Processed Values ===');
      developer.log('tanggalAwal (processed): $tanggalAwal');
      developer.log('tanggalAkhir (processed): $tanggalAkhir');
      developer.log('namaPetugas (processed): $namaPetugas');

      // Parse related models with error handling
      PenitipModel? penitipData;
      if (json['penitip'] != null) {
        try {
          developer.log('=== DEBUG: Parsing Penitip Data ===');
          developer.log('Raw penitip data: ${json['penitip']}');
          penitipData = PenitipModel.fromJson(json['penitip']);
          developer.log(
            'Successfully parsed penitip data: ${penitipData.namaPenitip}',
          );
        } catch (e, stackTrace) {
          developer.log('Error parsing penitip data: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      PegawaiModel? pegawaiData;
      if (json['pegawai'] != null) {
        try {
          developer.log('=== DEBUG: Parsing Pegawai Data ===');
          developer.log('Raw pegawai data: ${json['pegawai']}');
          pegawaiData = PegawaiModel.fromJson(json['pegawai']);
          developer.log('Successfully parsed pegawai data');
        } catch (e, stackTrace) {
          developer.log('Error parsing pegawai data: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      List<BarangModel>? barangList;
      if (json['barang'] != null) {
        try {
          developer.log('=== DEBUG: Parsing Barang List ===');
          developer.log('Raw barang data: ${json['barang']}');
          barangList =
              (json['barang'] as List)
                  .map((item) => BarangModel.fromJson(item))
                  .toList();
          developer.log(
            'Successfully parsed ${barangList.length} barang items',
          );
        } catch (e, stackTrace) {
          developer.log('Error parsing barang list: $e');
          developer.log('Stack trace: $stackTrace');
        }
      }

      // Parsing ID values with safety checks
      final idPenitipan = parseIntValue(json['id_penitipan']);
      final idPenitip = parseIntValue(json['id_penitip']);
      final idPegawai =
          json['id_pegawai'] != null ? parseIntValue(json['id_pegawai']) : null;

      // Create and return the model
      final model = PenitipanBarangModel(
        idPenitipan: idPenitipan,
        idPenitip: idPenitip,
        tanggalAwalPenitipan: tanggalAwal,
        tanggalAkhirPenitipan: tanggalAkhir,
        namaPetugasQc: namaPetugas,
        idPegawai: idPegawai,
        penitip: penitipData,
        pegawai: pegawaiData,
        barang: barangList,
      );

      developer.log('=== DEBUG: Created PenitipanBarangModel ===');
      developer.log('idPenitipan: ${model.idPenitipan}');
      developer.log('idPenitip: ${model.idPenitip}');
      developer.log('tanggalAwalPenitipan: ${model.tanggalAwalPenitipan}');
      developer.log('tanggalAkhirPenitipan: ${model.tanggalAkhirPenitipan}');
      developer.log('namaPetugasQc: ${model.namaPetugasQc}');

      return model;
    } catch (e, stackTrace) {
      developer.log('=== ERROR: Failed to create PenitipanBarangModel ===');
      developer.log('Error: $e');
      developer.log('Stack trace: $stackTrace');

      // Gunakan model default untuk mencegah crash
      return PenitipanBarangModel(
        idPenitipan: 0,
        idPenitip: 0,
        tanggalAwalPenitipan: null,
        tanggalAkhirPenitipan: null,
        namaPetugasQc: 'Error: ${e.toString().substring(0, 20)}...',
      );
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
