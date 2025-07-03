import 'pembeli_model.dart';
import 'detail_keranjang_model.dart';

class KeranjangModel {
  final int idKeranjang;
  final int idPembeli;
  final PembeliModel? pembeli;
  final List<DetailKeranjangModel>? detailKeranjang;

  KeranjangModel({
    required this.idKeranjang,
    required this.idPembeli,
    this.pembeli,
    this.detailKeranjang,
  });

  factory KeranjangModel.fromJson(Map<String, dynamic> json) {
    List<DetailKeranjangModel>? details;

    if (json['detail_keranjang'] != null) {
      details =
          (json['detail_keranjang'] as List)
              .map((item) => DetailKeranjangModel.fromJson(item))
              .toList();
    }

    return KeranjangModel(
      idKeranjang: json['id_keranjang'] ?? 0,
      idPembeli: json['id_pembeli'] ?? 0,
      pembeli:
          json['pembeli'] != null
              ? PembeliModel.fromJson(json['pembeli'])
              : null,
      detailKeranjang: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_keranjang': idKeranjang, 'id_pembeli': idPembeli};
  }
}
