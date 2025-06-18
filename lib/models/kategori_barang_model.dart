class KategoriBarangModel {
  final int idKategori;
  final String namaKategori;
  final String? deskripsiKategori;
  final String? iconKategori;

  KategoriBarangModel({
    required this.idKategori,
    required this.namaKategori,
    this.deskripsiKategori,
    this.iconKategori,
  });

  factory KategoriBarangModel.fromJson(Map<String, dynamic> json) {
    try {
      // Pastikan konversi ke int untuk id_kategori
      int id;
      if (json['id_kategori'] is int) {
        id = json['id_kategori'];
      } else if (json['id_kategori'] is String) {
        id = int.parse(json['id_kategori']);
      } else {
        print('Warning: id_kategori tidak valid: ${json['id_kategori']}');
        id = 0; // Default value
      }

      return KategoriBarangModel(
        idKategori: id,
        namaKategori: json['nama_kategori']?.toString() ?? '',
        deskripsiKategori: json['deskripsi_kategori']?.toString(),
        iconKategori: json['icon_kategori']?.toString(),
      );
    } catch (e) {
      print('Error parsing KategoriBarangModel: $e');
      print('JSON data: $json');
      // Return default model sebagai fallback
      return KategoriBarangModel(
        idKategori: 0,
        namaKategori: json['nama_kategori']?.toString() ?? 'Kategori',
        deskripsiKategori: null,
        iconKategori: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kategori': idKategori,
      'nama_kategori': namaKategori,
      'deskripsi_kategori': deskripsiKategori,
      'icon_kategori': iconKategori,
    };
  }
}
