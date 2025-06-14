import 'package:flutter/material.dart';
import '../../api/penitipan_barang_api.dart';
import '../../api/penitip_api.dart';
import '../../api/barang_api.dart';
import '../../api/api_service.dart';
import '../../api/foto_barang_api.dart';
import '../../models/penitipan_barang_model.dart';
import '../../models/barang_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/foto_barang_model.dart';
import '../../utils/local_storage.dart';
import 'barang_detail_page.dart';

class BarangPenitipPage extends StatefulWidget {
  const BarangPenitipPage({super.key});

  @override
  State<BarangPenitipPage> createState() => _BarangPenitipPageState();
}

class _BarangPenitipPageState extends State<BarangPenitipPage> {
  final PenitipanBarangApi _penitipanApi = PenitipanBarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  final BarangApi _barangApi = BarangApi();
  final ApiService _apiService = ApiService();
  final FotoBarangApi _fotoBarangApi = FotoBarangApi();

  List<PenitipanBarangModel> _penitipanList = [];
  List<BarangModel> _barangList = [];
  Map<int, FotoBarangModel?> _thumbnails =
      {}; // Menyimpan thumbnail untuk setiap barang
  bool _isLoading = true;
  String? _errorMessage;
  UserProfileModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await LocalStorage.getProfile();
      final userData = await LocalStorage.getUser();

      print("Mencoba mendapatkan data penitip untuk tampilan barang...");

      if (userData != null) {
        try {
          // Coba dapatkan data penitip berdasarkan ID user
          print(
            "Menggunakan ID user ${userData.idUser} untuk mendapatkan data penitip",
          );
          final penitipResponse = await _penitipApi.getPenitipByUserId(
            userData.idUser,
          );

          if (penitipResponse != null && penitipResponse['success']) {
            final penitipData = penitipResponse['data'];
            final idPenitip = penitipData['id_penitip'];

            print('ID penitip ditemukan melalui user ID: $idPenitip');

            // Simpan ID penitip ke storage untuk penggunaan berikutnya
            await LocalStorage.saveData('id_penitip', idPenitip.toString());

            await _loadBarangData(idPenitip);
            return;
          } else {
            print(
              'API merespons tanpa data penitip yang valid: $penitipResponse',
            );
          }
        } catch (e) {
          print('Error mendapatkan data penitip dari ID user: $e');
        }
      } else {
        print('Data user tidak ditemukan di local storage');
      }

      // Fallback: Coba dari profile local jika mendapatkan dari user ID gagal
      if (profile != null && profile.penitip != null) {
        print(
          'Menggunakan data penitip dari profil lokal: ID ${profile.penitip!.idPenitip}',
        );
        setState(() {
          _userProfile = profile;
        });
        await _loadBarangData(profile.penitip!.idPenitip);
      } else {
        print('Data penitip tidak ditemukan di profil lokal');

        // Cek apakah ada ID penitip tersimpan di local storage
        final idPenitip = await LocalStorage.getPenitipId();
        if (idPenitip != null) {
          print('Menggunakan ID penitip dari local storage: $idPenitip');
          await _loadBarangData(idPenitip);
          return;
        }

        setState(() {
          _errorMessage = 'Data profil penitip tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fatal saat memuat data profil: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data profil: $e';
        _isLoading = false;
      });
    }
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

  Future<void> _loadBarangData(int idPenitip) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _barangApi.getBarangByPenitip(idPenitip);

      if (response is List) {
        final barangList =
            response.map((item) => BarangModel.fromJson(item)).toList();
        print("Berhasil mendapatkan ${barangList.length} barang dari penitip");

        setState(() {
          _barangList = barangList;
          _isLoading = false;
        });

        // Fetch thumbnails untuk setiap barang
        for (var barang in barangList) {
          await _fetchThumbnailFoto(barang.idBarang);
        }
      } else {
        print("Format response tidak dikenali: $response");
        setState(() {
          _barangList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error saat memuat data barang: $e");
      setState(() {
        _errorMessage = 'Gagal memuat data barang: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Penitipan Saya'),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        onPressed: () {
                          if (_userProfile?.penitip != null) {
                            _loadBarangData(_userProfile!.penitip!.idPenitip);
                          } else {
                            _loadUserProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
              : _barangList.isEmpty
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
                      'Belum ada barang yang dititipkan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anda belum menitipkan barang di ReuseMart',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  if (_userProfile?.penitip != null) {
                    await _loadBarangData(_userProfile!.penitip!.idPenitip);
                  }
                },
                color: Colors.green.shade700,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _barangList.length,
                  itemBuilder: (context, index) {
                    final barang = _barangList[index];
                    return _buildBarangItem(barang);
                  },
                ),
              ),
    );
  }

  Widget _buildBarangItem(BarangModel barang) {
    final thumbnail = _thumbnails[barang.idBarang];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BarangDetailPage(
                    idBarang: barang.idBarang,
                    initialData: barang,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar barang
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    thumbnail != null
                        ? Image.network(
                          _apiService.getImageUrl(thumbnail.urlFoto),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildNoImage(),
                        )
                        : _buildNoImage(),
              ),

              const SizedBox(width: 16),

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
                    ),

                    const SizedBox(height: 4),

                    // Kategori
                    if (barang.kategori != null)
                      Text(
                        barang.kategori!.namaKategori,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Harga
                    Text(
                      'Rp ${_formatRupiah(barang.harga)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status barang
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        size: 30,
        color: Colors.grey.shade400,
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
}
