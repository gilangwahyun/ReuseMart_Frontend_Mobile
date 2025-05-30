import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/barang_api.dart';
import '../../api/user_api.dart';
import '../../api/penitip_api.dart';
import '../../api/penitipan_barang_api.dart';
import '../../models/barang_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/penitip_model.dart';
import '../../models/penitipan_barang_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import 'barang_penitip_page.dart';
import 'penitipan_list_page.dart';

class PenitipHomePage extends StatefulWidget {
  const PenitipHomePage({super.key});

  @override
  State<PenitipHomePage> createState() => _PenitipHomePageState();
}

class _PenitipHomePageState extends State<PenitipHomePage> {
  final UserApi _userApi = UserApi();
  final AuthApi _authApi = AuthApi();
  final PenitipApi _penitipApi = PenitipApi();
  final BarangApi _barangApi = BarangApi();
  final PenitipanBarangApi _penitipanBarangApi = PenitipanBarangApi();

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

      // Setelah mendapatkan profil, ambil data barang terbaru untuk dashboard
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

      // Ambil data barang dari API
      final response = await _barangApi.getBarangByPenitip(idPenitip!);

      if (response is List) {
        final barangList =
            response.map((item) => BarangModel.fromJson(item)).toList();

        // Ambil 5 barang terbaru untuk dashboard
        final recentBarang = barangList.take(5).toList();

        setState(() {
          _recentBarang = recentBarang;
          _isLoading = false;
        });
      } else {
        print("API mengembalikan format yang tidak dikenali: $response");
        setState(() {
          _recentBarang = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error saat memuat data barang: $e");
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
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

  void _navigateToPenitipanList() {
    // Navigasi ke halaman daftar penitipan
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PenitipanListPage()),
    );
  }

  void _navigateToBarangList() {
    // Navigasi ke halaman daftar barang
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarangPenitipPage()),
    );
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
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadUserData(),
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
        title: const Text('ReuseMart'),
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
              _buildMenuButtons(),
              _buildRecentBarangSection(),
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
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
                child: _buildInfoCard(
                  title: 'Saldo Anda',
                  value:
                      'Rp ${_formatRupiah(_userProfile?.penitip?.saldo ?? 0)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Poin Reward',
                  value: '${_userProfile?.poin ?? 0} Poin',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.shade700),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: color.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMenuButton(
                  title: 'Riwayat Penitipan',
                  icon: Icons.history,
                  color: Colors.indigo,
                  onTap: _navigateToPenitipanList,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMenuButton(
                  title: 'Barang Saya',
                  icon: Icons.inventory,
                  color: Colors.teal,
                  onTap: _navigateToBarangList,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.shade700, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBarangSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Barang Terbaru Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_recentBarang.isNotEmpty)
                TextButton(
                  onPressed: _navigateToBarangList,
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _recentBarang.isEmpty
              ? _buildEmptyBarangState()
              : Column(
                children:
                    _recentBarang
                        .map((barang) => _buildBarangItem(barang))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyBarangState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigasi ke detail barang
        },
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
}
