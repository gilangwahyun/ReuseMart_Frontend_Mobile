import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../api/barang_api.dart';
import '../../api/kategori_barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../models/barang_model.dart';
import '../../models/kategori_barang_model.dart';
import '../../models/foto_barang_model.dart';
import 'dart:developer' as developer;
import 'produk_page.dart';

class InformasiUmumPage extends StatefulWidget {
  const InformasiUmumPage({super.key});

  @override
  State<InformasiUmumPage> createState() => _InformasiUmumPageState();
}

class _InformasiUmumPageState extends State<InformasiUmumPage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Beranda', 'icon': Icons.home},
    {'title': 'Produk', 'icon': Icons.shopping_bag},
    {'title': 'Cara Kerja', 'icon': Icons.help_outline},
    {'title': 'Tentang Kami', 'icon': Icons.info_outline},
    {'title': 'FAQ', 'icon': Icons.question_answer},
  ];

  // Tambahan untuk menampilkan produk
  final BarangApi _barangApi = BarangApi();
  final KategoriBarangApi _kategoriApi = KategoriBarangApi();
  final FotoBarangApi _fotoApi = FotoBarangApi();

  List<BarangModel>? _barangList;
  Map<int, FotoBarangModel?> _thumbnails = {};
  bool _isLoadingProducts = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang() async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      // Ambil semua barang aktif
      final response = await _barangApi.getAllActiveBarang();

      if (response != null && response['data'] != null) {
        List<dynamic> data = response['data'];
        List<BarangModel> barangList =
            data.map((item) => BarangModel.fromJson(item)).toList();

        setState(() {
          _barangList = barangList;
          _thumbnails.clear(); // Reset thumbnail cache
        });

        // Load thumbnails for each barang
        _loadThumbnails(barangList);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat barang: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadThumbnails(List<BarangModel> barangList) async {
    for (var barang in barangList) {
      try {
        final thumbnail = await _fotoApi.getThumbnailFoto(barang.idBarang);

        if (mounted) {
          setState(() {
            _thumbnails[barang.idBarang] = thumbnail;
          });
        }
      } catch (e) {
        print(
          'Gagal memuat thumbnail untuk barang ${barang.idBarang}: ${e.toString()}',
        );
      }
    }
  }

  // Function to check if warranty is still valid
  bool isWarrantyValid(String? warrantyDate) {
    if (warrantyDate == null || warrantyDate.isEmpty) {
      return false;
    }

    developer.log('Checking warranty date: $warrantyDate');

    try {
      DateTime? warrantyDateTime;

      // Try DD/MM/YYYY format first
      if (warrantyDate.contains('/')) {
        final parts = warrantyDate.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = int.tryParse(parts[2]) ?? 2000;
          warrantyDateTime = DateTime(year, month, day);
        }
      } 
      // Try YYYY-MM-DD format
      else if (warrantyDate.contains('-')) {
        try {
          warrantyDateTime = DateTime.parse(warrantyDate);
        } catch (e) {
          final parts = warrantyDate.split('-');
          if (parts.length == 3) {
            final year = int.tryParse(parts[0]) ?? 2000;
            final month = int.tryParse(parts[1]) ?? 1;
            final day = int.tryParse(parts[2]) ?? 1;
            warrantyDateTime = DateTime(year, month, day);
          }
        }
      }
      // Try to directly parse the date
      else {
        try {
          warrantyDateTime = DateTime.parse(warrantyDate);
        } catch (e) {
          // If all parsing attempts fail, try to extract numbers and assume it's a future date
          final RegExp regExp = RegExp(r'\d+');
          final matches = regExp.allMatches(warrantyDate);
          if (matches.isNotEmpty) {
            // If we find any numbers, assume it's a valid warranty
            return true;
          }
        }
      }
      
      if (warrantyDateTime != null) {
        final currentDate = DateTime.now();
        // Compare with current date
        final isValid = warrantyDateTime.isAfter(currentDate);
        developer.log('Warranty date: $warrantyDateTime, Current: $currentDate, Valid: $isValid');
        return isValid;
      }
      
      // If we couldn't parse the date but it's not empty, assume it's valid
      developer.log('Could not parse warranty date format: $warrantyDate - assuming valid');
      return true;
    } catch (e) {
      developer.log('Error parsing warranty date: $e');
      // If there's an error in parsing but the warranty string exists, assume it's valid
      return true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]['title']),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.login);
            },
            child: const Text(
              'Masuk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeTab(),
          const ProdukPage(),
          _buildHowItWorksTab(),
          _buildAboutUsTab(),
          _buildFAQTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items:
            _pages
                .map(
                  (page) => BottomNavigationBarItem(
                    icon: Icon(page['icon']),
                    label: page['title'],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Utama
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade400, Colors.green.shade700],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selamat Datang di ReuseMart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Platform Konsinyasi Barang Bekas',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Apa itu ReuseMart?
          _buildSection(
            title: 'Apa itu ReuseMart?',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ReuseMart adalah platform konsinyasi barang bekas yang mengelola penjualan barang bekas melalui sistem penitipan. Anda cukup datang ke gudang kami, dan kami akan menangani seluruh proses penjualan hingga Anda mendapatkan hasil penjualan.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.money,
                        title: 'Untung Lebih',
                        description:
                            'Dapatkan hasil optimal dari barang bekas Anda',
                        color: Colors.green.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.speed,
                        title: 'Proses Cepat',
                        description:
                            'Penitipan langsung di gudang dan proses QC transparan',
                        color: Colors.blue.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.eco,
                        title: 'Ramah Lingkungan',
                        description:
                            'Barang yang tidak terjual dapat didonasikan dengan poin reward',
                        color: Colors.amber.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.verified_user,
                        title: 'Fleksibel',
                        description:
                            'Masa penitipan 30 hari dengan opsi perpanjangan',
                        color: Colors.purple.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call to Action - View Products
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Jelajahi Produk Kami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Temukan berbagai produk bekas berkualitas dari ReuseMart',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Lihat Produk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Produk tab
                    setState(() {
                      _selectedIndex = 1;
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Call to Action
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Siap untuk bergabung dengan ReuseMart?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daftar sekarang dan mulai jual atau beli barang bekas dengan mudah',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    AppRoutes.navigateTo(context, AppRoutes.login);
                  },
                  child: const Text('Masuk Sekarang'),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey.shade100,
            child: const Center(
              child: Text(
                '© 2023 ReuseMart. Semua hak dilindungi.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBarang,
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
    
    if (_barangList == null || _barangList!.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada barang tersedia',
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
    
    // Tampilkan maksimal 6 produk (2 baris dengan 3 kolom)
    final displayedItems = _barangList!.take(6).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayedItems.length,
      itemBuilder: (context, index) {
        final barang = displayedItems[index];
        // Check if warranty is valid
        final bool hasValidWarranty = isWarrantyValid(barang.masaGaransi);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.detailBarang,
                arguments: {'id_barang': barang.idBarang},
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child:
                          barang.gambarUtama.isNotEmpty
                              ? Image.network(
                                barang.gambarUtama,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 130,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                              )
                              : Container(
                                height: 130,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                    ),
                    // Status barang sebagai badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Baik', // Nilai default untuk kondisi barang
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Warranty badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasValidWarranty
                                ? Icons.verified_outlined
                                : Icons.not_interested,
                              color: hasValidWarranty
                                ? Colors.green.shade300
                                : Colors.grey.shade400,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hasValidWarranty
                                  ? 'Garansi: ${barang.masaGaransi}'
                                  : 'Tanpa Garansi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: hasValidWarranty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barang.namaBarang,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          barang.kategori?.namaKategori ?? 'Umum',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${_formatRupiah(barang.harga)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRupiah(double price) {
    int priceInt = price.toInt(); // Konversi ke int
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

  Widget _buildHowItWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bagaimana ReuseMart Bekerja?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Untuk Penitip
          const Text(
            'Alur Proses Penitipan Barang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildStepCard(
            number: 1,
            title: 'Datang ke Gudang ReuseMart',
            description:
                'Kunjungi gudang ReuseMart untuk membawa barang bekas Anda yang ingin dititipkan.',
            icon: Icons.location_on,
          ),
          _buildStepCard(
            number: 2,
            title: 'Quality Control',
            description:
                'Barang Anda akan diperiksa kualitasnya oleh petugas gudang ReuseMart.',
            icon: Icons.verified,
          ),
          _buildStepCard(
            number: 3,
            title: 'Pembuatan Akun oleh CS',
            description:
                'Customer Service akan membuatkan akun penitip untuk Anda jika belum memilikinya.',
            icon: Icons.person_add,
          ),
          _buildStepCard(
            number: 4,
            title: 'Proses Manajerial',
            description:
                'Tim manajerial akan menginput informasi barang dan menentukan detail penitipan.',
            icon: Icons.admin_panel_settings,
          ),
          _buildStepCard(
            number: 5,
            title: 'Masa Penitipan 30 Hari',
            description:
                'Barang Anda akan dititipkan selama 30 hari untuk dijual di platform ReuseMart.',
            icon: Icons.calendar_today,
          ),
          _buildStepCard(
            number: 6,
            title: 'Opsi Perpanjangan',
            description:
                'Setelah 30 hari, Anda memiliki waktu 7 hari untuk memutuskan memperpanjang masa penitipan atau mengambil barang kembali. Perpanjangan hanya bisa dilakukan sekali.',
            icon: Icons.update,
          ),
          _buildStepCard(
            number: 7,
            title: 'Pengalihan Hak Barang',
            description:
                'Jika tidak ada konfirmasi dalam 7 hari, barang masuk list kategori dan owner berhak mengalokasikan untuk donasi. Anda tetap mendapatkan poin reward donasi.',
            icon: Icons.card_giftcard,
          ),

          const SizedBox(height: 32),

          // Untuk Pembeli
          const Text(
            'Untuk Pembeli',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildStepCard(
            number: 1,
            title: 'Browse Produk',
            description:
                'Jelajahi berbagai produk bekas berkualitas di aplikasi ReuseMart.',
            icon: Icons.search,
          ),
          _buildStepCard(
            number: 2,
            title: 'Pilih & Beli',
            description:
                'Pilih produk yang Anda inginkan dan lakukan pembelian dengan mudah.',
            icon: Icons.shopping_cart,
          ),
          _buildStepCard(
            number: 3,
            title: 'Proses Pembayaran',
            description:
                'Lakukan pembayaran melalui berbagai metode yang tersedia.',
            icon: Icons.credit_card,
          ),
          _buildStepCard(
            number: 4,
            title: 'Terima Barang',
            description:
                'Barang akan dikirimkan ke alamat Anda oleh tim ReuseMart.',
            icon: Icons.local_shipping,
          ),

          const SizedBox(height: 32),

          // Diagram Masa Penitipan
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
                const Text(
                  'Masa Penitipan Barang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 8, color: Colors.green.shade400),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Container(height: 8, color: Colors.amber.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '30 Hari\nMasa Penitipan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '7 Hari\nMasa Keputusan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• Perpanjangan masa penitipan hanya dapat dilakukan 1 kali untuk 30 hari berikutnya',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Barang tanpa keputusan setelah 7 hari akan dialokasikan untuk donasi',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                AppRoutes.navigateTo(context, AppRoutes.login);
              },
              child: const Text('Mulai Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang ReuseMart',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey.shade300,
              height: 200,
              width: double.infinity,
              child: const Center(
                child: Icon(Icons.image, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Visi Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Menjadi platform konsinyasi terkemuka yang mendorong ekonomi sirkular dan mengurangi dampak lingkungan melalui jual-beli barang bekas yang berkualitas.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          const Text(
            'Misi Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildMissionItem(
            'Menyediakan platform yang aman dan terpercaya untuk jual-beli barang bekas.',
          ),
          _buildMissionItem(
            'Membantu penitip mendapatkan nilai maksimal dari barang bekas mereka.',
          ),
          _buildMissionItem(
            'Menawarkan produk berkualitas dengan harga terjangkau untuk pembeli.',
          ),
          _buildMissionItem(
            'Berkontribusi pada upaya pengurangan sampah dan pemanfaatan kembali produk.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Nilai-Nilai Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  icon: Icons.verified,
                  title: 'Kepercayaan',
                  color: Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildValueCard(
                  icon: Icons.eco,
                  title: 'Keberlanjutan',
                  color: Colors.green.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  icon: Icons.handshake,
                  title: 'Kerjasama',
                  color: Colors.purple.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildValueCard(
                  icon: Icons.recycling,
                  title: 'Inovasi',
                  color: Colors.amber.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hubungi Kami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildContactItem(Icons.email, 'info@reusemart.com'),
                const SizedBox(height: 8),
                _buildContactItem(Icons.phone, '+62 812 3456 7890'),
                const SizedBox(height: 8),
                _buildContactItem(
                  Icons.location_on,
                  'Jl. Daur Ulang No. 123, Jakarta',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan yang Sering Diajukan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            question: 'Apa itu ReuseMart?',
            answer:
                'ReuseMart adalah platform konsinyasi barang bekas yang menghubungkan penitip barang dengan calon pembeli. Kami membantu penitip menjual barang bekas mereka dengan mudah dan menguntungkan.',
          ),
          _buildFaqItem(
            question: 'Bagaimana cara menitipkan barang?',
            answer:
                'Untuk menitipkan barang, Anda perlu datang langsung ke gudang ReuseMart dengan membawa barang yang ingin dititipkan. Petugas gudang akan melakukan pemeriksaan kualitas, dan Customer Service kami akan membuatkan akun penitip untuk Anda. Selanjutnya, barang akan diproses oleh tim manajerial untuk diinputkan informasinya dan dijual melalui platform kami.',
          ),
          _buildFaqItem(
            question: 'Berapa lama masa penitipan barang?',
            answer:
                'Masa penitipan awal adalah 30 hari. Setelah itu, Anda memiliki waktu 7 hari untuk memutuskan apakah ingin memperpanjang masa penitipan selama 30 hari lagi atau mengambil barang kembali. Perpanjangan hanya dapat dilakukan satu kali. Jika tidak ada konfirmasi dalam 7 hari tersebut, barang akan masuk ke list kategori dan hak alokasi untuk donasi menjadi milik owner. Penitip tetap mendapatkan poin reward donasi.',
          ),
          _buildFaqItem(
            question: 'Berapa komisi yang diambil ReuseMart?',
            answer:
                'ReuseMart mengambil komisi sebesar 10-20% dari harga jual, tergantung pada kategori dan kondisi barang. Komisi ini digunakan untuk biaya operasional, penyimpanan, pemasaran, dan proses penjualan.',
          ),
          _buildFaqItem(
            question: 'Kapan saya akan menerima pembayaran?',
            answer:
                'Setelah barang terjual, pembayaran akan diproses dalam waktu 3-5 hari kerja dan ditransfer ke rekening bank yang telah Anda daftarkan.',
          ),
          _buildFaqItem(
            question: 'Apakah ada jaminan barang akan terjual?',
            answer:
                'Kami tidak dapat menjamin bahwa semua barang akan terjual, tetapi kami akan berusaha memasarkan barang Anda dengan optimal. Jika masa penitipan berakhir dan barang belum terjual, Anda dapat memperpanjang masa penitipan atau mengambil barang kembali.',
          ),
          _buildFaqItem(
            question: 'Bagaimana dengan kondisi dan kualitas barang?',
            answer:
                'Semua barang yang diterima akan melalui proses pemeriksaan kualitas oleh petugas gudang kami. Kami hanya menerima barang bekas dengan kondisi yang masih layak jual. Kondisi barang akan dicantumkan dengan jelas pada deskripsi produk.',
          ),
          _buildFaqItem(
            question:
                'Apa yang terjadi jika saya tidak mengambil keputusan setelah masa penitipan berakhir?',
            answer:
                'Jika tidak ada konfirmasi dalam 7 hari setelah masa penitipan 30 hari berakhir, barang akan masuk ke list kategori dan hak alokasi untuk donasi menjadi milik owner ReuseMart. Sebagai penitip, Anda tetap akan mendapatkan poin reward donasi yang dapat ditukarkan dengan berbagai hadiah menarik.',
          ),
          _buildFaqItem(
            question:
                'Apakah ReuseMart melayani pengiriman ke seluruh Indonesia?',
            answer:
                'Ya, ReuseMart melayani pengiriman ke seluruh Indonesia melalui berbagai jasa ekspedisi terpercaya. Biaya pengiriman ditanggung oleh pembeli.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                const Text(
                  'Pertanyaan lainnya?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan hubungi tim layanan pelanggan kami melalui:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildContactButton(
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildContactButton(
                      icon: Icons.chat,
                      label: 'Chat',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildContactButton(
                      icon: Icons.phone,
                      label: 'Telepon',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(icon, size: 32, color: Colors.green.shade300),
        ],
      ),
    );
  }

  Widget _buildMissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue.shade700),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
