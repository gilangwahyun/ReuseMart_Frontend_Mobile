class KomisiPegawaiModel {
  final int idKomisiPegawai;
  final int idTransaksi;
  final int idPegawai;
  final double jumlahKomisi;
  final Map<String, dynamic>? transaksi;
  final Map<String, dynamic>? pegawai;

  KomisiPegawaiModel({
    required this.idKomisiPegawai,
    required this.idTransaksi,
    required this.idPegawai,
    required this.jumlahKomisi,
    this.transaksi,
    this.pegawai,
  });

  factory KomisiPegawaiModel.fromJson(Map<String, dynamic> json) {
    return KomisiPegawaiModel(
      idKomisiPegawai: json['id_komisi_pegawai'],
      idTransaksi: json['id_transaksi'],
      idPegawai: json['id_pegawai'],
      jumlahKomisi: (json['jumlah_komisi'] is int)
          ? (json['jumlah_komisi'] as int).toDouble()
          : json['jumlah_komisi'],
      transaksi: json['transaksi'],
      pegawai: json['pegawai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_komisi_pegawai': idKomisiPegawai,
      'id_transaksi': idTransaksi,
      'id_pegawai': idPegawai,
      'jumlah_komisi': jumlahKomisi,
      'transaksi': transaksi,
      'pegawai': pegawai,
    };
  }
} 