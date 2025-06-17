import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/barang_api.dart';
import '../../api/api_service.dart';
import '../../models/barang_model.dart';
import '../../models/foto_barang_model.dart';

class BarangDetailPage extends StatefulWidget {
  final int idBarang;
  final BarangModel? initialData;

  const BarangDetailPage({super.key, required this.idBarang, this.initialData});

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage>
    with TickerProviderStateMixin {
  final BarangApi _barangApi = BarangApi();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  BarangModel? _barang;
  List<FotoBarangModel> _fotoList = [];
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Tab controller
  late TabController _tabController;
  final List<String> _tabs = ['Detail', 'Penitipan'];

  @override
  void initState() {
    super.initState();

    developer.log('BarangDetailPage initialized for ID: ${widget.idBarang}');
    
    // Jika ada initial data, gunakan dulu
    // Inisialisasi TabController
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Gunakan initial data jika tersedia
    if (widget.initialData != null) {
      developer.log('Using initial data for barang: ${widget.initialData!.namaBarang}');
      setState(() {
        _barang = widget.initialData;
        _setupTabs(_barang);
        _isLoading = false;
      });
    }

    // Load data lengkap
    _loadBarangDetail();
  }

  void _setupTabs(BarangModel? barang) {
    List<String> newTabs = ['Detail', 'Penitipan'];

    // Tambah tab Transaksi jika barang sudah terjual
    if (barang?.statusBarang == 'Habis') {
      newTabs.add('Transaksi');
    }

    // Tambah tab Donasi jika barang sudah didonasikan
    if (barang?.statusBarang == 'Barang sudah Didonasikan') {
      newTabs.add('Donasi');
    }

    // Update tabs jika berbeda
    if (!listEquals(_tabs, newTabs)) {
      final currentIndex = _tabController.index;

      setState(() {
        _tabs.clear();
        _tabs.addAll(newTabs);

        _tabController.dispose();
        _tabController = TabController(length: newTabs.length, vsync: this);

        if (currentIndex < newTabs.length) {
          _tabController.index = currentIndex;
        }
      });
    }
  }

  bool listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadBarangDetail() async {
    if (!mounted) return;

    try {
      developer.log('Loading detail for barang ID: ${widget.idBarang}');
      
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
      // Konversi response ke model
      final barangDetail = BarangModel.fromJson(barangResponse);
      print('=== DEBUG: Penitipan Data ===');
      print('Penitipan object: ${barangDetail.penitipanBarang}');
      if (barangDetail.penitipanBarang != null) {
        print('ID Penitipan: ${barangDetail.penitipanBarang!.idPenitipan}');
        print(
          'Tanggal Awal: ${barangDetail.penitipanBarang!.tanggalAwalPenitipan}',
        );
        print(
          'Tanggal Akhir: ${barangDetail.penitipanBarang!.tanggalAkhirPenitipan}',
        );
        print('Nama Petugas: ${barangDetail.penitipanBarang!.namaPetugasQc}');
      }

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
          _setupTabs(barangDetail);
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
        title: const Text('Detail Barang'),
        backgroundColor: Colors.green.shade600,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBarangDetail,
        child: TabBarView(
          controller: _tabController,
          children: _buildTabContents(barang, imageUrls),
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

  Widget _buildErrorScaffold() {
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

  List<Widget> _buildTabContents(BarangModel barang, List<String> imageUrls) {
    List<Widget> widgets = [];

    // Default tabs
    widgets.add(_buildDetailTab(barang, imageUrls));
    widgets.add(_buildPenitipanTab(barang));

    // Conditional tabs
    if (_tabs.contains('Transaksi')) {
      widgets.add(_buildTransaksiTab(barang));
    }
    if (_tabs.contains('Donasi')) {
      widgets.add(_buildDonasiTab(barang));
    }

    return widgets;
  }

  Widget _buildDetailTab(BarangModel barang, List<String> imageUrls) {
    return SingleChildScrollView(
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
                        barang.statusBarang,
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
                _buildDetailSection('Informasi Barang', [
                  if (barang.kategori != null)
                    _buildDetailRow('Kategori', barang.kategori!.namaKategori),
                  if (barang.berat != null)
                    _buildDetailRow('Berat', '${barang.berat} gram'),
                  if (barang.masaGaransi != null &&
                      barang.masaGaransi!.isNotEmpty)
                    _buildDetailRow(
                      'Garansi',
                      _formatDate(barang.masaGaransi!),
                    ),
                  if (barang.masaGaransi == null || barang.masaGaransi!.isEmpty)
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenitipanTab(BarangModel barang) {
    print('=== DEBUG: Building Penitipan Tab ===');
    print('Barang ID: ${barang.idBarang}');
    print('Has Penitipan: ${barang.penitipanBarang != null}');

    if (barang.penitipanBarang != null) {
      print('Penitipan ID: ${barang.penitipanBarang!.idPenitipan}');
      print('Tanggal Awal: ${barang.penitipanBarang!.tanggalAwalPenitipan}');
      print('Tanggal Akhir: ${barang.penitipanBarang!.tanggalAkhirPenitipan}');
      print('Nama Petugas: ${barang.penitipanBarang!.namaPetugasQc}');
    }

    // Data penitipan sekarang selalu tersedia dari response barang
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Penitipan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (barang.penitipanBarang != null) ...[
                    _buildDetailRow(
                      'ID Penitipan',
                      '#${barang.penitipanBarang!.idPenitipan}',
                    ),

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
                    // Debug sebelum format tanggal
                    Builder(
                      builder: (context) {
                        final rawTanggalAwal =
                            barang.penitipanBarang!.tanggalAwalPenitipan;
                        final formattedTanggalAwal = _formatDateWithTime(
                          rawTanggalAwal ?? '-',
                        );
                        print('=== DEBUG: Formatting Tanggal Awal ===');
                        print('Raw: $rawTanggalAwal');
                        print('Formatted: $formattedTanggalAwal');
                        return _buildDetailRow(
                          'Tanggal Awal',
                          formattedTanggalAwal,
                        );
                      },
                    ),

                    // Debug sebelum format tanggal akhir
                    Builder(
                      builder: (context) {
                        final rawTanggalAkhir =
                            barang.penitipanBarang!.tanggalAkhirPenitipan;
                        final formattedTanggalAkhir = _formatDateWithTime(
                          rawTanggalAkhir ?? '-',
                        );
                        print('=== DEBUG: Formatting Tanggal Akhir ===');
                        print('Raw: $rawTanggalAkhir');
                        print('Formatted: $formattedTanggalAkhir');
                        return _buildDetailRow(
                          'Tanggal Akhir',
                          formattedTanggalAkhir,
                        );
                      },
                    ),

                    if (barang.penitipanBarang!.namaPetugasQc != null)
                      _buildDetailRow(
                        'Petugas QC',
                        barang.penitipanBarang!.namaPetugasQc ?? '-',
                      ),

                    if (barang.penitipanBarang!.pegawai != null)
                      _buildDetailRow(
                        'Hunter',
                        barang.penitipanBarang!.pegawai!.namaPegawai,
                      ),

                    if (barang.penitipanBarang!.penitip != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      Text(
                        'Informasi Penitip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        'Nama',
                        barang.penitipanBarang!.penitip!.namaPenitip,
                      ),

                      _buildDetailRow(
                        'Alamat',
                        barang.penitipanBarang!.penitip!.alamat,
                      ),

                      _buildDetailRow(
                        'Telepon',
                        barang.penitipanBarang!.penitip!.noTelepon,
                      ),
                    ],

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Status Barang: ${barang.statusBarang}',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Text(
                      'Diskripsi',
                      'Data penitipan tidak tersedia',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiTab(BarangModel barang) {
    print('=== DEBUG: Building Transaksi Tab ===');
    print('Has DetailTransaksi: ${barang.detailTransaksi != null}');
    if (barang.detailTransaksi != null) {
      print(
        'Detail Transaksi ID: ${barang.detailTransaksi!.idDetailTransaksi}',
      );
      print(
        'Transaksi: ${barang.detailTransaksi!.transaksi != null ? "exists" : "null"}',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.green.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  if (barang.detailTransaksi != null) ...[
                    // ID Transaksi
                    _buildDetailRow(
                      'Status Transaksi',
                      '#${barang.detailTransaksi!.transaksi!.statusTransaksi}',
                    ),

                    // Harga Item
                    _buildDetailRow(
                      'Tanggal Transaksi',
                      '${_formatDateWithTime(barang.detailTransaksi!.transaksi!.tanggalTransaksi ?? '-')}',
                    ),
                  ] else
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Data transaksi tidak tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return Colors.green.shade100;
      case 'pending':
      case 'menunggu pembayaran':
        return Colors.orange.shade100;
      case 'dibatalkan':
      case 'gagal':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getPaymentStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return Colors.green.shade800;
      case 'pending':
      case 'menunggu pembayaran':
        return Colors.orange.shade800;
      case 'dibatalkan':
      case 'gagal':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildDonasiTab(BarangModel barang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Donasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),

              if (barang.alokasiDonasi != null) ...[
                _buildDetailRow('Status', barang.statusBarang),

                _buildDetailRow(
                  'Tanggal Donasi',
                  barang.alokasiDonasi!.tanggalDonasi != null
                      ? _formatDateWithTime(
                        barang.alokasiDonasi!.tanggalDonasi!,
                      )
                      : 'Belum diproses',
                ),

                if (barang.alokasiDonasi?.requestDonasi?.organisasi != null)
                  _buildDetailRow(
                    'Organisasi',
                    barang
                        .alokasiDonasi!
                        .requestDonasi!
                        .organisasi!
                        .namaOrganisasi,
                  ),

                if (barang.alokasiDonasi?.requestDonasi != null)
                  _buildDetailRow(
                    'Deskripsi',
                    barang.alokasiDonasi!.requestDonasi!.deskripsi,
                  ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          barang.statusBarang.toLowerCase() ==
                                  'barang sudah didonasikan'
                              ? 'Barang ini telah didonasikan'
                              : 'Barang ini dialokasikan untuk donasi',
                          style: TextStyle(color: Colors.amber.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Text(
                  'Data donasi tidak tersedia',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
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

  String _formatDateWithTime(String isoDate) {
    print('=== DEBUG: Format Date With Time ===');
    print('Input date: $isoDate');

    if (isoDate == '-') {
      print('Returning default dash');
      return '-';
    }

    try {
      final date = DateTime.parse(isoDate);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      final formatted = '$day/$month/$year $hour:$minute WIB';
      print('Successfully formatted to: $formatted');
      return formatted;
    } catch (e) {
      print('Error formatting date: $e');
      if (isoDate.length >= 10) {
        final partial = isoDate.substring(0, 10);
        print('Returning partial date: $partial');
        return partial;
      }
      print('Returning original: $isoDate');
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
    _tabController.dispose();
    super.dispose();
  }
}
