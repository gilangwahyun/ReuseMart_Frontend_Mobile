import 'package:flutter/material.dart';
import '../../api/barang_api.dart';
import '../../api/kategori_barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../api/api_service.dart';
import '../../models/barang_model.dart';
import '../../models/kategori_barang_model.dart';
import '../../models/foto_barang_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import '../../widgets/notification_icon.dart';
import '../../pages/client/barang_detail_pembeli_page.dart'; // Pastikan path import benar

class HomePage extends StatefulWidget {
  final bool isEmbedded;

  const HomePage({super.key, this.isEmbedded = false});

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
  final ApiService _apiService = ApiService();

  List<BarangModel>? _barangList;
  Map<int, FotoBarangModel?> _thumbnails = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Base URL untuk mengakses foto dari Laravel storage
  final String _baseUrl =
      'https://api.reusemartuajy.my.id'; // Sesuaikan dengan URL API Anda

  @override
  void initState() {
    super.initState();
    print('=== DEBUG: HomePage initState ===');
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    print('=== DEBUG: _loadKategori started ===');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Mencoba mengambil data kategori...');
      final response = await _kategoriApi.getAllKategori();
      print('Response kategori: $response');

      // Periksa apakah response adalah array langsung atau objek dengan properti 'data'
      List<dynamic> data;
      if (response is List) {
        // Response adalah array langsung
        data = response;
      } else if (response is Map && response['data'] != null) {
        // Response adalah objek dengan properti 'data'
        data = response['data'];
      } else {
        print('Format response tidak valid: $response');
        setState(() {
          _errorMessage = 'Format data kategori tidak valid';
          _isLoading = false;
        });

        // Jika gagal memuat kategori, tetap load barang
        print('Gagal memuat kategori, tetap mencoba memuat barang...');
        await _loadBarang();
        return;
      }

      print('Data kategori: $data');

      // Pastikan data adalah List dan tidak kosong
      if (data.isNotEmpty) {
        List<KategoriBarangModel> categories = [];

        // Parsing data dengan error handling
        for (var item in data) {
          try {
            categories.add(KategoriBarangModel.fromJson(item));
          } catch (e) {
            print('Error parsing kategori: $e');
            print('Item yang error: $item');
          }
        }

        print('Berhasil parse ${categories.length} kategori');

        setState(() {
          _categories = categories;
          _categoriesName = [
            'Semua',
            ..._categories.map((e) => e.namaKategori).toList(),
          ];
        });
      } else {
        print('Data kategori kosong: $data');
        setState(() {
          _errorMessage = 'Data kategori kosong';
        });
      }

      // Setelah kategori dimuat, muat barang
      print('Memuat barang setelah kategori...');
      await _loadBarang();
    } catch (e, stack) {
      print('Exception saat memuat kategori: $e');
      print('Stack trace: $stack');
      setState(() {
        _errorMessage = 'Gagal memuat kategori: ${e.toString()}';
      });

      // Jika gagal memuat kategori, tetap load barang
      print('Gagal memuat kategori, tetap mencoba memuat barang...');
      await _loadBarang();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBarang() async {
    print('=== DEBUG: _loadBarang started ===');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic response;
      print('Current index: $_currentIndex');

      if (_currentIndex == 0) {
        // Ambil semua barang
        print('Mengambil semua barang aktif...');
        response = await _barangApi.getAllActiveBarang();
      } else {
        // Ambil barang berdasarkan kategori
        // Pastikan _currentIndex valid dan tidak melebihi panjang _categories
        if (_currentIndex > 0 && _currentIndex <= _categories.length) {
          // Gunakan ID kategori, bukan nama kategori
          int idKategori =
              _categories[_currentIndex - 1]
                  .idKategori; // -1 karena indeks 0 adalah "Semua"
          print('Mengambil barang untuk kategori ID: $idKategori');
          response = await _barangApi.getBarangByKategoriId(idKategori);
        } else {
          // Fallback ke semua barang jika indeks tidak valid
          print('Indeks tidak valid, mengambil semua barang...');
          response = await _barangApi.getAllActiveBarang();
        }
      }

      print('Response barang: $response');

      if (response != null && response['data'] != null) {
        List<dynamic> data = response['data'];
        print('Jumlah data barang: ${data.length}');

        List<BarangModel> barangList = [];
        for (var item in data) {
          try {
            barangList.add(BarangModel.fromJson(item));
          } catch (e) {
            print('Error parsing barang: $e');
            print('Item yang error: $item');
          }
        }

        print('Berhasil parse ${barangList.length} barang');

        // Set state untuk menampilkan barang terlebih dahulu
        setState(() {
          _barangList = barangList;
          _isLoading = false;
        });

        // Load thumbnails setelah barang ditampilkan
        print('Memuat thumbnails untuk ${barangList.length} barang...');
        _loadThumbnails(barangList);
      } else {
        print('Response barang tidak valid atau kosong');
        setState(() {
          _barangList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error saat memuat barang: $e');
      setState(() {
        _errorMessage = 'Gagal memuat barang: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadThumbnails(List<BarangModel> barangList) async {
    print('=== DEBUG: _loadThumbnails started ===');
    print('Jumlah barang untuk load thumbnail: ${barangList.length}');

    // Batasi jumlah barang yang akan dimuat thumbnailnya untuk performa
    final limitedList = barangList.take(8).toList();
    print('Dibatasi hanya ${limitedList.length} barang untuk performa');

    // Gunakan Future.wait untuk memuat thumbnail secara paralel
    try {
      await Future.wait(
        limitedList.map((barang) => _loadSingleThumbnail(barang)),
        eagerError: false,
      );
      print('Selesai memuat semua thumbnail');
    } catch (e) {
      print('Error saat memuat thumbnail secara paralel: $e');
    }
  }

  Future<void> _loadSingleThumbnail(BarangModel barang) async {
    try {
      print('Memuat thumbnail untuk barang ID: ${barang.idBarang}');
      final fotos = await _fotoApi.getFotoBarangByIdBarang(barang.idBarang);
      print(
        'Berhasil mendapatkan ${fotos.length} foto untuk barang ID: ${barang.idBarang}',
      );

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

        print('Thumbnail URL: ${thumbnail.urlFoto}');

        if (mounted) {
          setState(() {
            _thumbnails[barang.idBarang] = thumbnail;
          });

          // Preload image
          _preloadImage(thumbnail.urlFoto);
        }
      } else {
        print('Tidak ada foto untuk barang ID: ${barang.idBarang}');
      }
    } catch (e) {
      print('Gagal memuat thumbnail untuk barang ${barang.idBarang}: $e');
    }
  }

  void _preloadImage(String url) {
    final imageUrl = _apiService.getImageUrl(url);
    precacheImage(NetworkImage(imageUrl), context);
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
        AppRoutes.navigateAndReplace(context, AppRoutes.pembeliContainer);
      } else if (role == 'Penitip') {
        AppRoutes.navigateAndReplace(context, AppRoutes.penitipProfile);
      } else {
        // Jika role tidak dikenal, gunakan profil pembeli sebagai default
        AppRoutes.navigateAndReplace(context, AppRoutes.pembeliContainer);
      }
    } else {
      // Jika tidak ada data user, arahkan ke halaman login
      AppRoutes.navigateAndReplace(context, AppRoutes.login);
    }
  }

  void _navigateToDetail(int idBarang) {
    // Navigasi ke halaman detail barang
    print("DEBUG: Navigating to detail page for barang ID: $idBarang");
    try {
      // Gunakan BarangDetailPembeliPage untuk pembeli umum
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarangDetailPembeliPage(idBarang: idBarang),
        ),
      );
      print("DEBUG: Navigation method called successfully");
    } catch (e) {
      print("DEBUG ERROR: Failed to navigate: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.isEmbedded instead of checking route
    final bool isEmbedded = widget.isEmbedded;

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
          NotificationIcon(color: Colors.white, badgeColor: Colors.amber),
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
      // Only show bottom navigation when not embedded in container
      bottomNavigationBar:
          isEmbedded
              ? null
              : BottomNavigationBar(
                currentIndex: _selectedNavIndex,
                onTap: _onNavBarTapped,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.green.shade700,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Cari',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Keranjang',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profil',
                  ),
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
    // Jika belum ada kategori, tampilkan indikator loading
    if (_categoriesName.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoriesName.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          // Pastikan index valid
          if (index < 0 || index >= _categoriesName.length) {
            return const SizedBox.shrink();
          }

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
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }

    // Default icon
    return Icons.category;
  }

  Widget _buildProductGrid() {
    if (_barangList == null || _barangList!.isEmpty) {
      return Center(
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

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
        final thumbnail = _thumbnails[barang.idBarang];

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
                          thumbnail != null
                              ? Image.network(
                                _apiService.getImageUrl(thumbnail.urlFoto),
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return _buildNoImage(130);
                                },
                              )
                              : _buildNoImage(130),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(barang.statusBarang),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          barang.statusBarang == 'Aktif'
                              ? 'Tersedia'
                              : barang.statusBarang,
                          style: TextStyle(
                            color: _getStatusTextColor(barang.statusBarang),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
                              barang.masaGaransi != null &&
                                      barang.masaGaransi!.isNotEmpty
                                  ? Icons.verified_outlined
                                  : Icons.not_interested,
                              color:
                                  barang.masaGaransi != null &&
                                          barang.masaGaransi!.isNotEmpty
                                      ? Colors.green.shade300
                                      : Colors.grey.shade400,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                barang.masaGaransi != null &&
                                        barang.masaGaransi!.isNotEmpty
                                    ? 'Garansi: ${barang.masaGaransi}'
                                    : 'Tanpa Garansi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight:
                                      barang.masaGaransi != null &&
                                              barang.masaGaransi!.isNotEmpty
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
                          barang.kategori?.namaKategori ??
                              _getCategoryNameById(barang.idKategori) ??
                              'Umum',
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

  Widget _buildNoImage(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey.shade500,
        ),
      ),
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
                            AppRoutes.pembeliContainer,
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
                          Navigator.pushNamed(context, AppRoutes.settings);
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

  // Mendapatkan nama kategori berdasarkan ID
  String? _getCategoryNameById(int idKategori) {
    // Cari kategori berdasarkan ID
    try {
      final category = _categories.firstWhere(
        (cat) => cat.idKategori == idKategori,
        orElse: () => throw Exception('Kategori tidak ditemukan'),
      );
      return category.namaKategori;
    } catch (e) {
      print('Kategori dengan ID $idKategori tidak ditemukan: $e');
      return null;
    }
  }
}
