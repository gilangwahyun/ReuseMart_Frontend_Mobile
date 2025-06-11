import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../api/barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../models/barang_model.dart';
import '../../models/foto_barang_model.dart';

class BarangDetailPage extends StatefulWidget {
  final int idBarang;
  final BarangModel? initialData;

  const BarangDetailPage({super.key, required this.idBarang, this.initialData});

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage> {
  final BarangApi _barangApi = BarangApi();
  final FotoBarangApi _fotoApi = FotoBarangApi();

  bool _isLoading = true;
  String? _errorMessage;
  BarangModel? _barang;
  List<FotoBarangModel> _fotoList = [];
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    developer.log('BarangDetailPage initialized for ID: ${widget.idBarang}');
    
    // Jika ada initial data, gunakan dulu
    if (widget.initialData != null) {
      developer.log('Using initial data for barang: ${widget.initialData!.namaBarang}');
      setState(() {
        _barang = widget.initialData;
        _isLoading = false;
      });
    }

    // Tetap ambil data lengkap dari API
    _loadBarangDetail();
  }

  Future<void> _loadBarangDetail() async {
    try {
      developer.log('Loading detail for barang ID: ${widget.idBarang}');
      
      setState(() {
        _isLoading = _barang == null; // set loading hanya jika belum ada data
      });

      // Ambil detail barang
      final response = await _barangApi.getBarangById(widget.idBarang);
      developer.log('Received API response for barang: $response');

      if (response != null) {
        BarangModel barangDetail;

        if (response is Map && response.containsKey('data')) {
          // Format response dengan wrapper
          developer.log('Response format: wrapped with data key');
          barangDetail = BarangModel.fromJson(response['data']);
        } else {
          // Format response langsung
          developer.log('Response format: direct object');
          barangDetail = BarangModel.fromJson(response);
        }

        developer.log('Successfully parsed barang detail: ${barangDetail.namaBarang}');

        // Load foto barang
        developer.log('Loading photos for barang ID: ${widget.idBarang}');
        final fotoResponse = await _fotoApi.getFotoByBarangId(widget.idBarang);
        List<FotoBarangModel> fotos = [];

        if (fotoResponse != null) {
          developer.log('Received photo response: $fotoResponse');
          if (fotoResponse is List) {
            fotos =
                fotoResponse
                    .map((item) => FotoBarangModel.fromJson(item))
                    .toList();
          } else if (fotoResponse is Map && fotoResponse.containsKey('data')) {
            final dataList = fotoResponse['data'] as List;
            fotos =
                dataList.map((item) => FotoBarangModel.fromJson(item)).toList();
          }
          developer.log('Parsed ${fotos.length} photos for the barang');
        } else {
          developer.log('No photos found for the barang');
        }

        if (mounted) {
          setState(() {
            _barang = barangDetail;
            _fotoList = fotos;
            _isLoading = false;
          });
          developer.log('State updated with barang data and photos');
        }
      } else {
        developer.log('ERROR: API returned null response for barang ID: ${widget.idBarang}');
        if (mounted) {
          setState(() {
            _errorMessage = 'Data barang tidak ditemukan';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error saat memuat detail barang: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail barang: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Jika masih loading dan tidak ada initial data
    if (_isLoading && widget.initialData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Barang'),
          backgroundColor: Colors.green.shade600,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
      );
    }

    // Jika ada error dan tidak ada initial data
    if (_errorMessage != null && widget.initialData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Barang'),
          backgroundColor: Colors.green.shade600,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBarangDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // Pastikan kita memiliki data barang (dari initial data atau hasil loading)
    final barang = _barang ?? widget.initialData!;

    // Buat list foto yang akan ditampilkan
    List<String> imageUrls = [];

    // Tambahkan foto utama jika ada
    if (barang.gambarUtama.isNotEmpty) {
      imageUrls.add(barang.gambarUtama);
    }

    // Tambahkan foto-foto lain dari foto_barang
    for (var foto in _fotoList) {
      // Hindari duplikat dengan gambar utama
      if (foto.url != barang.gambarUtama) {
        imageUrls.add(foto.url);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        backgroundColor: Colors.green.shade600,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBarangDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel / gallery
              _buildImageCarousel(imageUrls),

              // Info utama barang
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama barang
                    Text(
                      barang.namaBarang,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Harga dan Status
                    Row(
                      children: [
                        // Harga
                        Text(
                          'Rp ${_formatRupiah(barang.harga)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),

                        const Spacer(),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(barang.statusBarang),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            barang.statusBarang,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusTextColor(barang.statusBarang),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Divider(color: Colors.grey.shade300, height: 1),

                    const SizedBox(height: 16),

                    // Detail Info Section
                    _buildDetailSection('Informasi Barang', [
                      if (barang.kategori != null)
                        _buildDetailRow(
                          'Kategori',
                          barang.kategori!.namaKategori,
                        ),
                      if (barang.berat != null)
                        _buildDetailRow('Berat', '${barang.berat} gram'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Garansi',
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: barang.masaGaransi != null && barang.masaGaransi!.isNotEmpty
                              ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade600),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_outlined, color: Colors.green.shade700, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            barang.masaGaransi!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.not_interested, color: Colors.grey.shade600, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tidak ada garansi',
                                        style: TextStyle(
                                          fontSize: 14, 
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ],
                      ),
                      if (barang.rating != null)
                        _buildDetailRow('Rating', '${barang.rating}/5'),
                    ]),

                    const SizedBox(height: 16),

                    // Divider
                    Divider(color: Colors.grey.shade300, height: 1),

                    const SizedBox(height: 16),

                    // Data Penitipan
                    if (barang.penitipanBarang != null)
                      _buildDetailSection('Informasi Penitipan', [
                        _buildDetailRow(
                          'Tanggal Awal',
                          _formatDate(
                            barang.penitipanBarang!.tanggalAwalPenitipan,
                          ),
                        ),
                        _buildDetailRow(
                          'Tanggal Akhir',
                          _formatDate(
                            barang.penitipanBarang!.tanggalAkhirPenitipan,
                          ),
                        ),
                        _buildDetailRow(
                          'Petugas QC',
                          barang.penitipanBarang!.namaPetugasQc,
                        ),
                        if (barang.penitipanBarang!.pegawai != null)
                          _buildDetailRow(
                            'Hunter',
                            barang.penitipanBarang!.pegawai!.namaPegawai,
                          ),
                      ]),

                    const SizedBox(height: 16),

                    // Divider
                    Divider(color: Colors.grey.shade300, height: 1),

                    const SizedBox(height: 16),

                    // Deskripsi
                    Text(
                      'Diskripsi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      barang.deskripsi ?? 'Tidak ada deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      // No images available
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 60,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada gambar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Images available, build carousel
    return Column(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              developer.log('Rendering image at index $index: ${imageUrls[index]}');
              return GestureDetector(
                onTap: () {
                  // Implement full-screen view if needed
                },
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('Error loading image: $error');
                    return Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Image indicators
        if (imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.green.shade600
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        const SizedBox(height: 12),

        // Section items
        ...items,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),

          const SizedBox(width: 16),

          // Value
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return isoDate.substring(0, 10);
    }
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
