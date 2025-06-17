import 'keranjang_model.dart';
import 'barang_model.dart';

class DetailKeranjangModel {
  final int idDetailKeranjang;
  final int idKeranjang;
  final int idBarang;
  final KeranjangModel? keranjang;
  final BarangModel? barang;

  DetailKeranjangModel({
    required this.idDetailKeranjang,
    required this.idKeranjang,
    required this.idBarang,
    this.keranjang,
    this.barang,
  });

  factory DetailKeranjangModel.fromJson(Map<String, dynamic> json) {
    return DetailKeranjangModel(
      idDetailKeranjang: json['id_detail_keranjang'] ?? 0,
      idKeranjang: json['id_keranjang'] ?? 0,
      idBarang: json['id_barang'] ?? 0,
      keranjang:
          json['keranjang'] != null
              ? KeranjangModel.fromJson(json['keranjang'])
              : null,
      barang:
          json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_detail_keranjang': idDetailKeranjang,
      'id_keranjang': idKeranjang,
      'id_barang': idBarang,
    };
  }
}
