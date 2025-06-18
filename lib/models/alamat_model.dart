import 'pembeli_model.dart';

class AlamatModel {
  final int idAlamat;
  final int idPembeli;
  final String alamatLengkap;
  final String kodePos;
  final bool isUtama;
  final PembeliModel? pembeli;

  AlamatModel({
    required this.idAlamat,
    required this.idPembeli,
    required this.alamatLengkap,
    required this.kodePos,
    required this.isUtama,
    this.pembeli,
  });

  factory AlamatModel.fromJson(Map<String, dynamic> json) {
    return AlamatModel(
      idAlamat: json['id_alamat'] ?? 0,
      idPembeli: json['id_pembeli'] ?? 0,
      alamatLengkap: json['alamat_lengkap'] ?? '',
      kodePos: json['kode_pos'] ?? '',
      isUtama: json['is_utama'] == 1 || json['is_utama'] == true,
      pembeli:
          json['pembeli'] != null
              ? PembeliModel.fromJson(json['pembeli'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_alamat': idAlamat,
      'id_pembeli': idPembeli,
      'alamat_lengkap': alamatLengkap,
      'kode_pos': kodePos,
      'is_utama': isUtama ? 1 : 0,
    };
  }
}
