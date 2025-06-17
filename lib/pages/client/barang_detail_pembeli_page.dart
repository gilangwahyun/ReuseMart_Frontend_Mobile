import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/barang_api.dart';
import '../../api/api_service.dart';
import '../../models/barang_model.dart';
import '../../models/foto_barang_model.dart';

class BarangDetailPembeliPage extends StatefulWidget {
  final int idBarang;
  final BarangModel? initialData;

  const BarangDetailPembeliPage({
    super.key,
    required this.idBarang,
    this.initialData,
  });

  @override
  State<BarangDetailPembeliPage> createState() =>
      _BarangDetailPembeliPageState();
}

class _BarangDetailPembeliPageState extends State<BarangDetailPembeliPage> {
  final BarangApi _barangApi = BarangApi();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  BarangModel? _barang;
  List<FotoBarangModel> _fotoList = [];
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Gunakan initial data jika tersedia
    if (widget.initialData != null) {
      setState(() {
        _barang = widget.initialData;
        _isLoading = false;
      });
    }

    // Load data lengkap
    _loadBarangDetail();
  }

  Future<void> _loadBarangDetail() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = _barang == null;
      });

      // Load detail barang dengan semua relasinya
      final barangResponse = await _barangApi.getBarangById(widget.idBarang);
      print('=== DEBUG: Raw API Response ===');
      print(barangResponse);

      if (barangResponse == null) {
        throw Exception('Data barang tidak ditemukan');
      }

      // Konversi response ke model
      final barangDetail = BarangModel.fromJson(barangResponse);

      // Konversi foto barang dari response
      List<FotoBarangModel> fotos = [];
      if (barangResponse['foto_barang'] != null) {
        fotos =
            (barangResponse['foto_barang'] as List)
                .map((foto) => FotoBarangModel.fromJson(foto))
                .toList();
      }

      if (mounted) {
        setState(() {
          _barang = barangDetail;
          _fotoList = fotos;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('=== DEBUG: Error Loading Barang ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
    // Loading state
    if (_isLoading && widget.initialData == null) {
      return _buildLoadingScaffold();
    }

    // Error state
    if (_errorMessage != null && widget.initialData == null) {
      return _buildErrorScaffold();
    }

    // Main content
    final barang = _barang ?? widget.initialData!;
    final imageUrls = _buildImageUrls();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.green.shade600,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBarangDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel
              _buildImageCarousel(imageUrls),

              // Main content
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
                        Text(
                          'Rp ${_formatRupiah(barang.harga)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
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
                            barang.statusBarang == 'Aktif'
                                ? 'Tersedia'
                                : barang.statusBarang,
                            style: TextStyle(
                              color: _getStatusTextColor(barang.statusBarang),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Informasi Barang
                    _buildDetailSection('Informasi Produk', [
                      if (barang.kategori != null)
                        _buildDetailRow(
                          'Kategori',
                          barang.kategori!.namaKategori,
                        ),
                      if (barang.berat != null)
                        _buildDetailRow('Berat', '${barang.berat} gram'),
                      if (barang.masaGaransi != null &&
                          barang.masaGaransi!.isNotEmpty)
                        _buildDetailRow(
                          'Garansi',
                          _formatDate(barang.masaGaransi!),
                        ),
                      if (barang.masaGaransi == null ||
                          barang.masaGaransi!.isEmpty)
                        _buildDetailRow('Garansi', 'Tidak ada garansi'),
                      if (barang.rating != null)
                        _buildDetailRow('Rating', '${barang.rating}/5'),
                    ]),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Deskripsi
                    Text(
                      'Deskripsi',
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

                    // Info tentang ReuseMart
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.eco, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'ReuseMart',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Produk ini merupakan barang bekas berkualitas yang telah melalui proses seleksi dan quality control. Dengan membeli produk ini, Anda telah berkontribusi untuk mengurangi limbah dan mendukung ekonomi sirkular.',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
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

  List<String> _buildImageUrls() {
    List<String> urls = [];

    if (_fotoList.isNotEmpty) {
      urls.addAll(_fotoList.map((foto) => foto.urlFoto));
    }

    return urls;
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
        ),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
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

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          height: 250,
          color: Colors.black,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              String imageUrl = images[index];
              return CachedNetworkImage(
                imageUrl: _apiService.getImageUrl(imageUrl),
                fit: BoxFit.contain,
                maxHeightDiskCache: 800,
                memCacheHeight: 800,
                useOldImageOnUrlChange: true,
                placeholder:
                    (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade600,
                      ),
                    ),
                errorWidget: (context, url, error) {
                  developer.log('Error loading image: $url, error: $error');
                  return Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade500,
                            size: 50,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
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
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 16),
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
      return isoDate;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green.shade100;
      case 'non-aktif':
        return Colors.grey.shade200;
      case 'terjual':
      case 'habis':
        return Colors.blue.shade100;
      case 'barang untuk donasi':
      case 'barang sudah didonasikan':
        return Colors.amber.shade100;
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
      case 'habis':
        return Colors.blue.shade800;
      case 'barang untuk donasi':
      case 'barang sudah didonasikan':
        return Colors.amber.shade800;
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
