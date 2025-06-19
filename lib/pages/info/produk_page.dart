import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../api/barang_api.dart';
import '../../api/kategori_barang_api.dart';
import '../../api/foto_barang_api.dart';
import '../../models/barang_model.dart';
import '../../models/kategori_barang_model.dart';
import '../../models/foto_barang_model.dart';
import '../../routes/app_routes.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final BarangApi _barangApi = BarangApi();
  final KategoriBarangApi _kategoriApi = KategoriBarangApi();
  final FotoBarangApi _fotoApi = FotoBarangApi();

  List<BarangModel>? _barangList;
  Map<int, FotoBarangModel?> _thumbnails = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  List<KategoriBarangModel>? _categories;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadBarang(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _kategoriApi.getAllKategori();
      
      if (response != null && response['data'] != null) {
        List<dynamic> data = response['data'];
        List<KategoriBarangModel> categoryList =
            data.map((item) => KategoriBarangModel.fromJson(item)).toList();

        setState(() {
          _categories = categoryList;
        });
      }
    } catch (e) {
      developer.log('Error loading categories: $e');
    }
  }

  Future<void> _loadBarang() async {
    setState(() {
      _isLoading = true;
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
        developer.log(
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

  List<BarangModel> _getFilteredProducts() {
    if (_barangList == null) return [];
    
    return _barangList!.where((barang) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty || 
          barang.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (barang.deskripsi ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by category
      final matchesCategory = _selectedCategory == null || 
          barang.kategori?.namaKategori == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Tersedia'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Column(
        children: [
          // Search and filter area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Category filter dropdown
                if (_categories != null && _categories!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Pilih Kategori'),
                        value: _selectedCategory,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ..._categories!.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.namaKategori,
                              child: Text(category.namaKategori),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Products grid
          Expanded(
            child: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
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
      );
    }
    
    final filteredItems = _getFilteredProducts();
    
    if (filteredItems.isEmpty) {
      return Center(
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
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Tidak ada produk yang sesuai dengan filter'
                  : 'Tidak ada produk tersedia',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  child: const Text('Hapus Filter'),
                ),
              ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final barang = filteredItems[index];
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
} 