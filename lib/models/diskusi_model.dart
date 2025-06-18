import 'barang_model.dart';

class DiskusiModel {
  final int idDiskusi;
  final int idBarang;
  final String komen;
  final BarangModel? barang;

  DiskusiModel({
    required this.idDiskusi,
    required this.idBarang,
    required this.komen,
    this.barang,
  });

  factory DiskusiModel.fromJson(Map<String, dynamic> json) {
    return DiskusiModel(
      idDiskusi: json['id_diskusi'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      komen: json['komen'] ?? '',
      barang:
          json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_diskusi': idDiskusi, 'id_barang': idBarang, 'komen': komen};
  }
}
