class JadwalModel {
  final int idJadwal;
  final int idTransaksi;
  final int? idPegawai;
  final String tanggal;
  final String statusJadwal;
  final Map<String, dynamic>? pegawai;
  final Map<String, dynamic>? transaksi;

  JadwalModel({
    required this.idJadwal,
    required this.idTransaksi,
    this.idPegawai,
    required this.tanggal,
    required this.statusJadwal,
    this.pegawai,
    this.transaksi,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      idJadwal: json['id_jadwal'],
      idTransaksi: json['id_transaksi'],
      idPegawai: json['id_pegawai'],
      tanggal: json['tanggal'],
      statusJadwal: json['status_jadwal'],
      pegawai: json['pegawai'],
      transaksi: json['transaksi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_jadwal': idJadwal,
      'id_transaksi': idTransaksi,
      'id_pegawai': idPegawai,
      'tanggal': tanggal,
      'status_jadwal': statusJadwal,
    };
  }
}
