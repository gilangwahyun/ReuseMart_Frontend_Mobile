import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/barang_api.dart';
import '../../api/user_api.dart';
import '../../api/penitip_api.dart';
import '../../models/barang_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/penitip_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';

class PenitipHomePage extends StatefulWidget {
  const PenitipHomePage({super.key});

  @override
  State<PenitipHomePage> createState() => _PenitipHomePageState();
}

class _PenitipHomePageState extends State<PenitipHomePage> {
  final UserApi _userApi = UserApi();
  final AuthApi _authApi = AuthApi();
  final BarangApi _barangApi = BarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  UserProfileModel? _userProfile;
  List<BarangModel> _recentBarang = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 0; // 0 untuk home penitip

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cek login status
      final isLoggedIn = await _authApi.isLoggedIn();

      if (!isLoggedIn) {
        if (mounted) {
          AppRoutes.navigateAndClear(context, AppRoutes.login);
        }
        return;
      }

      // Ambil data profil
      final profile = await LocalStorage.getProfile();
      if (profile == null || profile.penitip == null) {
        setState(() {
          _errorMessage = 'Profil penitip tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userProfile = profile;
      });

      // Ambil data user
      final userData = await LocalStorage.getUser();
      if (userData != null) {
        try {
          // Ambil data penitip berdasarkan ID user
          final penitipResponse = await _penitipApi.getPenitipByUserId(
            userData.idUser,
          );

          if (penitipResponse != null && penitipResponse['success'] == true) {
            print('Detail penitip berhasil diambil dari API');
            final penitipData = penitipResponse['data'];

            // Jika ada data penitipan, tampilkan jumlahnya
            if (penitipData['penitipan_barang'] != null) {
              final penitipanCount = penitipData['penitipan_barang'].length;
              print('Jumlah penitipan: $penitipanCount');
            }
          }
        } catch (e) {
          print('Error saat mengambil detail penitip: $e');
        }
      }

      // Setelah mendapatkan profil, ambil data barang terbaru
      await _loadRecentBarang();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentBarang() async {
    try {
      int? idPenitip;

      // Cara 1: Gunakan ID penitip dari profil
      if (_userProfile?.penitip != null) {
        idPenitip = _userProfile!.penitip!.idPenitip;
        print("Menggunakan ID penitip dari profil: $idPenitip");
      } else {
        // Cara 2: Coba ambil ID penitip yang tersimpan di localStorage
        idPenitip = await LocalStorage.getPenitipId();
        if (idPenitip != null) {
          print("Menggunakan ID penitip dari storage: $idPenitip");
        } else {
          // Cara 3: Coba ambil dari string
          final idPenitipStr = await LocalStorage.getData('id_penitip');
          if (idPenitipStr != null && idPenitipStr.isNotEmpty) {
            idPenitip = int.tryParse(idPenitipStr);
            print("Menggunakan ID penitip dari storage (string): $idPenitip");
          } else {
            print("Tidak menemukan ID penitip yang valid");
            setState(() {
              _recentBarang = [];
              _isLoading = false;
            });
            return;
          }
        }
      }

      final response = await _barangApi.getBarangByPenitip(idPenitip!);

      if (response is List && response.isNotEmpty) {
        final barangList =
            response.map((item) => BarangModel.fromJson(item)).toList();

        setState(() {
          _recentBarang = barangList;
          _isLoading = false;
        });
      } else {
        print("API mengembalikan data kosong atau bukan list: $response");
        setState(() {
          _recentBarang = [];
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

  void _onNavBarTapped(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Sudah di halaman home
        break;
      case 1:
        // Navigasi ke halaman profil
        AppRoutes.navigateAndReplace(context, AppRoutes.penitipProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ReuseMart'),
          backgroundColor: Colors.green.shade600,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ReuseMart'),
          backgroundColor: Colors.green.shade600,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReuseMart - Penitip'),
        backgroundColor: Colors.green.shade600,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              _buildMenu(),
              _buildRecentBarang(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavBarTapped,
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.green.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile?.name ?? 'Penitip',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_userProfile?.penitip?.saldo ?? 0}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poin Anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_userProfile?.poin ?? 0} Poin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Penitip',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMenuButton(
                icon: Icons.inventory,
                label: 'Barang Saya',
                onTap:
                    () =>
                        AppRoutes.navigateTo(context, AppRoutes.penitipBarang),
              ),
              _buildMenuButton(
                icon: Icons.history,
                label: 'Riwayat',
                onTap:
                    () => AppRoutes.navigateTo(
                      context,
                      AppRoutes.riwayatPenitipan,
                    ),
              ),
              _buildMenuButton(
                icon: Icons.payments,
                label: 'Pendapatan',
                onTap:
                    () => AppRoutes.navigateTo(
                      context,
                      AppRoutes.pendapatanPenitip,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green.shade600, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBarang() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barang Terbaru Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _recentBarang.isEmpty
              ? Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada barang yang dititipkan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children:
                    _recentBarang
                        .take(5)
                        .map((barang) => _buildBarangItem(barang))
                        .toList(),
              ),
          if (_recentBarang.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    AppRoutes.navigateTo(context, AppRoutes.penitipBarang);
                  },
                  child: Text(
                    'Lihat Semua Barang',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarangItem(BarangModel barang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              barang.gambarUtama.isNotEmpty
                  ? Image.network(
                    barang.gambarUtama,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildNoImage(),
                  )
                  : _buildNoImage(),
        ),
        title: Text(
          barang.namaBarang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rp ${_formatRupiah(barang.harga)}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(barang.statusBarang),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                barang.statusBarang,
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusTextColor(barang.statusBarang),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: 24,
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
        return Colors.blue.shade100;
      case 'barang untuk donasi':
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
        return Colors.blue.shade800;
      case 'barang untuk donasi':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
