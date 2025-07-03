import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/penitipan_barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../api/api_service.dart';
import '../../models/penitipan_barang_model.dart';
import '../../models/barang_model.dart';
import '../../models/foto_barang_model.dart';
import '../../utils/local_storage.dart';

class PenitipanListPage extends StatefulWidget {
  const PenitipanListPage({super.key});

  @override
  State<PenitipanListPage> createState() => _PenitipanListPageState();
}

class _PenitipanListPageState extends State<PenitipanListPage> {
  final PenitipanBarangApi _penitipanBarangApi = PenitipanBarangApi();
  final FotoBarangApi _fotoBarangApi = FotoBarangApi();
  final ApiService _apiService = ApiService();

  List<PenitipanBarangModel> _penitipanList = [];
  Map<int, FotoBarangModel?> _thumbnails =
      {}; // Menyimpan thumbnail untuk setiap barang
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPenitipanData();
  }

  // Fungsi untuk mengambil thumbnail foto
  Future<void> _fetchThumbnailFoto(int idBarang) async {
    try {
      final fotos = await _fotoBarangApi.getFotoBarangByIdBarang(idBarang);

      if (fotos.isNotEmpty) {
        // Pilih foto dengan is_thumbnail === true
        final thumbnail = fotos.firstWhere(
          (f) => f.isThumbnail,
          orElse: () {
            // Fallback ke foto pertama (id_foto_barang terkecil)
            final sortedFotos = List.from(fotos)
              ..sort((a, b) => a.idFotoBarang.compareTo(b.idFotoBarang));
            return sortedFotos.first;
          },
        );

        setState(() {
          _thumbnails[idBarang] = thumbnail;
        });
      }
    } catch (e) {
      print('Error fetching foto barang: $e');
    }
  }

  Future<void> _loadPenitipanData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ambil ID penitip
      final idPenitip = await LocalStorage.getPenitipId();
      if (idPenitip == null) {
        setState(() {
          _errorMessage = 'ID Penitip tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final response = await _penitipanBarangApi.getPenitipanByPenitipId(
        idPenitip,
      );

      if (response is Map &&
          response.containsKey('data') &&
          response['data'] is List) {
        // Format response: {success: true, message: "...", data: [...]}
        final penitipanData = response['data'] as List;

        final penitipanList =
            penitipanData
                .map((item) => PenitipanBarangModel.fromJson(item))
                .toList();

        // Urutkan berdasarkan tanggal penitipan terbaru
        penitipanList.sort((a, b) {
          final dateA = a.tanggalAwalPenitipan ?? '';
          final dateB = b.tanggalAwalPenitipan ?? '';
          return dateB.compareTo(dateA);
        });

        setState(() {
          _penitipanList = penitipanList;
          _isLoading = false;
        });

        // Fetch thumbnails untuk setiap barang dalam penitipan
        for (var penitipan in penitipanList) {
          if (penitipan.barang != null) {
            for (var barang in penitipan.barang!) {
              await _fetchThumbnailFoto(barang.idBarang);
            }
          }
        }
      } else if (response is List) {
        // Format response langsung list
        final penitipanList =
            response
                .map((item) => PenitipanBarangModel.fromJson(item))
                .toList();

        // Urutkan berdasarkan tanggal penitipan terbaru
        penitipanList.sort((a, b) {
          final dateA = a.tanggalAwalPenitipan ?? '';
          final dateB = b.tanggalAwalPenitipan ?? '';
          return dateB.compareTo(dateA);
        });

        setState(() {
          _penitipanList = penitipanList;
          _isLoading = false;
        });

        // Fetch thumbnails untuk setiap barang dalam penitipan
        for (var penitipan in penitipanList) {
          if (penitipan.barang != null) {
            for (var barang in penitipan.barang!) {
              await _fetchThumbnailFoto(barang.idBarang);
            }
          }
        }
      } else {
        setState(() {
          _penitipanList = [];
          _isLoading = false;
          _errorMessage = 'Format data tidak valid';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data penitipan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penitipan'),
        backgroundColor: Colors.green.shade600,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadPenitipanData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : _penitipanList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada penitipan barang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anda belum pernah menitipkan barang di ReuseMart',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadPenitipanData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _penitipanList.length,
                  itemBuilder: (context, index) {
                    final penitipan = _penitipanList[index];
                    return _buildPenitipanCard(penitipan);
                  },
                ),
              ),
    );
  }

  Widget _buildPenitipanCard(PenitipanBarangModel penitipan) {
    // Format tanggal dengan penanganan null
    String tglAwal = _formatDate(penitipan.tanggalAwalPenitipan ?? '-');
    String tglAkhir = _formatDate(penitipan.tanggalAkhirPenitipan ?? '-');

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header penitipan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID Penitipan dan Tanggal
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Penitipan #${penitipan.idPenitipan}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tglAwal,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Periode
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Periode: $tglAwal s/d $tglAkhir',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Petugas QC
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Petugas QC: ${penitipan.namaPetugasQc ?? "-"}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Daftar barang
          if (penitipan.barang == null || penitipan.barang!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada data barang',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Barang (${penitipan.barang!.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...penitipan.barang!
                      .map((barang) => _buildBarangItem(barang))
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarangItem(BarangModel barang) {
    final thumbnail = _thumbnails[barang.idBarang];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Gambar barang (jika ada)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child:
                thumbnail != null
                    ? CachedNetworkImage(
                      imageUrl: _apiService.getImageUrl(thumbnail.urlFoto),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      maxHeightDiskCache: 200,
                      memCacheHeight: 200,
                      useOldImageOnUrlChange: true,
                      placeholder:
                          (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                    )
                    : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
          ),

          const SizedBox(width: 12),

          // Informasi barang
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama barang
                Text(
                  barang.namaBarang,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Harga dan Status
                Row(
                  children: [
                    Text(
                      'Rp ${_formatRupiah(barang.harga)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(barang.statusBarang),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        barang.statusBarang,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusTextColor(barang.statusBarang),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Kategori
                if (barang.kategori != null)
                  Text(
                    barang.kategori!.namaKategori,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double price) {
    int priceInt = price.toInt();
    String priceStr = priceInt.toString();
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = priceStr[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }

    return result;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green.shade100;
      case 'non-aktif':
        return Colors.grey.shade200;
      case 'terjual':
        return Colors.blue.shade100;
      case 'barang untuk donasi':
        return Colors.amber.shade100;
      case 'habis':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green.shade800;
      case 'non-aktif':
        return Colors.grey.shade800;
      case 'terjual':
        return Colors.blue.shade800;
      case 'barang untuk donasi':
        return Colors.amber.shade800;
      case 'habis':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate == '-') return '-';

    try {
      final date = DateTime.parse(isoDate);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      if (isoDate.length >= 10) {
        return isoDate.substring(0, 10);
      }
      return isoDate;
    }
  }
}
