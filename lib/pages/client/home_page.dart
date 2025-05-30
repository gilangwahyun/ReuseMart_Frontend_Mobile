import 'package:flutter/material.dart';
import '../../api/barang_api.dart';
import '../../api/kategori_barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../components/layouts/base_layout.dart';
import '../../models/barang_model.dart';
import '../../models/kategori_barang_model.dart';
import '../../models/foto_barang_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _selectedNavIndex = 0;
  List<KategoriBarangModel> _categories = [];
  List<String> _categoriesName = ['Semua'];

  final BarangApi _barangApi = BarangApi();
  final KategoriBarangApi _kategoriApi = KategoriBarangApi();
  final FotoBarangApi _fotoApi = FotoBarangApi();

  List<BarangModel>? _barangList;
  Map<int, FotoBarangModel?> _thumbnails = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Base URL untuk mengakses foto dari Laravel storage
  final String _baseUrl =
      'https://api.reusemart.com'; // Sesuaikan dengan URL API Anda

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _kategoriApi.getAllKategori();

      if (response != null && response['data'] != null) {
        List<dynamic> data = response['data'];
        List<KategoriBarangModel> categories =
            data.map((item) => KategoriBarangModel.fromJson(item)).toList();

        setState(() {
          _categories = categories;
          _categoriesName = [
            'Semua',
            ..._categories.map((e) => e.namaKategori).toList(),
          ];
        });

        // Setelah kategori dimuat, muat barang
        await _loadBarang();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat kategori: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBarang() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic response;

      if (_currentIndex == 0) {
        // Ambil semua barang
        response = await _barangApi.getAllActiveBarang();
      } else {
        // Ambil barang berdasarkan kategori
        String kategori = _categoriesName[_currentIndex];
        response = await _barangApi.getBarangByKategori(kategori);
      }

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
        _isLoading = false;
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

  void _onCategorySelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadBarang();
  }

  void _onNavBarTapped(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Sudah di Home
        break;
      case 1:
        // Implementasi untuk halaman cari
        break;
      case 2:
        // Implementasi untuk halaman keranjang
        break;
      case 3:
        // Navigasi ke halaman profile sesuai role
        _navigateToProfile();
        break;
    }
  }

  Future<void> _navigateToProfile() async {
    final userData = await LocalStorage.getUserMap();

    if (userData != null && userData['role'] != null) {
      final role = userData['role'];

      if (role == 'Pembeli') {
        AppRoutes.navigateAndReplace(context, AppRoutes.pembeliProfile);
      } else if (role == 'Penitip') {
        AppRoutes.navigateAndReplace(context, AppRoutes.penitipProfile);
      } else {
        // Jika role tidak dikenal, gunakan profil pembeli sebagai default
        AppRoutes.navigateAndReplace(context, AppRoutes.pembeliProfile);
      }
    } else {
      // Jika tidak ada data user, arahkan ke halaman login
      AppRoutes.navigateAndReplace(context, AppRoutes.login);
    }
  }

  void _navigateToDetail(int idBarang) {
    // Navigasi ke halaman detail barang
    // Anda bisa menggunakan Navigator atau AppRoutes
    // Contoh:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => DetailBarangPage(idBarang: idBarang),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _showDrawerMenu(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Search Container dengan Background Hijau
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 16),
          // Kategori Baru dengan desain yang lebih baik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Kategori",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCategoryList(),
          const SizedBox(height: 16),
          // Produk Terlaris
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Daftar Produk",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grid Barang
          Expanded(
            child:
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
                    )
                    : _barangList == null || _barangList!.isEmpty
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
                          Text(
                            'Tidak ada barang tersedia',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _buildProductGrid(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari barang daur ulang...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: (value) async {
          if (value.isNotEmpty) {
            setState(() {
              _isLoading = true;
            });

            try {
              final response = await _barangApi.searchBarangByName(value);

              if (response != null && response['data'] != null) {
                List<dynamic> data = response['data'];
                List<BarangModel> barangList =
                    data.map((item) => BarangModel.fromJson(item)).toList();

                setState(() {
                  _barangList = barangList;
                  _thumbnails.clear(); // Reset thumbnail cache
                  _isLoading = false;
                });

                // Load thumbnails for each barang
                _loadThumbnails(barangList);
              }
            } catch (e) {
              setState(() {
                _errorMessage = 'Gagal mencari barang: ${e.toString()}';
                _isLoading = false;
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoriesName.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onCategorySelected(index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == index
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _currentIndex == index
                                ? Colors.green.shade600
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(index),
                      color:
                          _currentIndex == index
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _categoriesName[index],
                    style: TextStyle(
                      color:
                          _currentIndex == index
                              ? Colors.green.shade800
                              : Colors.black87,
                      fontWeight:
                          _currentIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(int index) {
    // Daftar icon untuk kategori
    final List<IconData> icons = [
      Icons.category, // Semua
      Icons.home_outlined,
      Icons.electrical_services,
      Icons.phone_android,
      Icons.chair_outlined,
      Icons.checkroom_outlined,
      Icons.desktop_windows_outlined,
      Icons.kitchen,
      Icons.sports_soccer,
      Icons.book,
      Icons.toys,
      Icons.more_horiz,
    ];

    // Pastikan tidak out of range
    if (index < icons.length) {
      return icons[index];
    }

    // Default icon
    return Icons.category;
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _barangList!.length,
      itemBuilder: (context, index) {
        final barang = _barangList![index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              _navigateToDetail(barang.idBarang);
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

  // Menampilkan drawer menu
  void _showDrawerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ReuseMart',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Platform Konsinyasi Barang Bekas',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      ListTile(
                        leading: Icon(Icons.home, color: Colors.green.shade600),
                        title: const Text('Beranda'),
                        onTap: () {
                          Navigator.pop(context); // Tutup drawer
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.category,
                          color: Colors.green.shade600,
                        ),
                        title: const Text('Kategori'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigasi ke halaman kategori
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.shopping_cart,
                          color: Colors.green.shade600,
                        ),
                        title: const Text('Keranjang Belanja'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigasi ke halaman keranjang
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.history,
                          color: Colors.green.shade600,
                        ),
                        title: const Text('Riwayat Transaksi'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigasi ke halaman profil
                          AppRoutes.navigateTo(
                            context,
                            AppRoutes.pembeliProfile,
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: Colors.green.shade600,
                        ),
                        title: const Text('Tentang ReuseMart'),
                        onTap: () {
                          Navigator.pop(context);
                          AppRoutes.navigateTo(
                            context,
                            AppRoutes.informasiUmum,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.settings,
                          color: Colors.green.shade600,
                        ),
                        title: const Text('Pengaturan'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigasi ke halaman pengaturan
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
