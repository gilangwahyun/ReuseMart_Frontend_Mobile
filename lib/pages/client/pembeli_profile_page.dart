import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../models/user_profile_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import 'dart:convert';
import 'riwayat_transaksi_page.dart';

class PembeliProfilePage extends StatefulWidget {
  const PembeliProfilePage({super.key});

  @override
  State<PembeliProfilePage> createState() => _PembeliProfilePageState();
}

class _PembeliProfilePageState extends State<PembeliProfilePage> {
  UserProfileModel? _userProfile;
  bool _isLoading = true;
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi();
  int _selectedNavIndex = 3; // 3 untuk halaman profile
  bool _isPersonalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Tambahkan listener untuk perubahan fokus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Periksa dan muat ulang data saat halaman mendapatkan fokus
        final focusScope = FocusScope.of(context);
        focusScope.addListener(() {
          if (focusScope.hasFocus && mounted) {
            _loadUserData();
          }
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Periksa status login terlebih dahulu
      final isLoggedIn = await _authApi.isLoggedIn();
      print("Status login: $isLoggedIn");

      // Coba dapatkan data dari local storage
      final localProfile = await LocalStorage.getProfile();

      if (localProfile != null) {
        print("Data profil ditemukan di local storage");
        print("Data profil local: ${jsonEncode(localProfile.toJson())}");

        setState(() {
          _userProfile = localProfile;
        });

        if (!isLoggedIn) {
          try {
            if (localProfile.user.token != null &&
                localProfile.user.token!.isNotEmpty) {
              await LocalStorage.saveToken(localProfile.user.token!);
              print('Token dari data lokal dipulihkan');
            }
          } catch (e) {
            print('Gagal memulihkan token: $e');
          }
        }
      }

      // Jika sudah login, coba perbarui data dari API
      if (isLoggedIn ||
          (localProfile?.user.token != null &&
              localProfile!.user.token!.isNotEmpty)) {
        try {
          print("Mencoba mengambil data profil dari API...");
          final apiProfile = await _userApi.getProfile();

          if (apiProfile != null) {
            print("Profil berhasil diambil dari API");
            print("Data profil API: ${jsonEncode(apiProfile.toJson())}");

            setState(() {
              _userProfile = apiProfile;
            });

            // Simpan data terbaru ke local storage
            await LocalStorage.saveProfile(apiProfile);
            print('Data profil diperbarui dari API');
          }
        } catch (e) {
          print('Error saat mengambil profil dari API: $e');
          if (_userProfile == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Gagal memuat data profil dari server. Menggunakan data lokal.',
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data profil: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
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
        // Navigasi ke Home
        AppRoutes.navigateAndReplace(context, AppRoutes.home);
        break;
      case 1:
        // Implementasi untuk halaman cari
        break;
      case 2:
        // Implementasi untuk halaman keranjang
        break;
      case 3:
        // Sudah di halaman profil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.green.shade600,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigasi ke halaman pengaturan
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body:
          _userProfile == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 100,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Anda belum login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        AppRoutes.navigateAndClear(context, AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Login Sekarang'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildPersonalInfoSection(),
                    _buildProfileMenu(),
                    const SizedBox(height: 20),
                  ],
                ),
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.green.shade50,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green.shade200,
            child: Icon(Icons.person, size: 60, color: Colors.green.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.name ?? 'Nama Pembeli',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.user.email ?? 'email@example.com',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          if (_userProfile?.phone.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.phone,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
          if (_userProfile?.user.role == 'Pembeli' &&
              _userProfile?.pembeli != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pembeli',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_userProfile!.poin > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_userProfile!.poin} Poin',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    if (_userProfile?.pembeli == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isPersonalInfoExpanded = !_isPersonalInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Informasi Pribadi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isPersonalInfoExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isPersonalInfoExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    'Nama Lengkap',
                    _userProfile!.pembeli!.namaPembeli,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    'No. Telepon',
                    _userProfile!.pembeli!.noHpDefault ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Email', _userProfile!.user.email),
                  const SizedBox(height: 12),
                  _buildInfoItem('Status', 'Pembeli Aktif'),
                  const SizedBox(height: 12),
                  _buildInfoItem('Jumlah Poin', '${_userProfile!.poin} Poin'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Riwayat Transaksi',
            subtitle: 'Lihat semua transaksi Anda',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatTransaksiPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.local_shipping,
            title: 'Alamat Pengiriman',
            subtitle: 'Kelola alamat pengiriman Anda',
            onTap: () {
              // Navigasi ke halaman alamat pengiriman
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.shopping_cart,
            title: 'Keranjang Belanja',
            subtitle: 'Lihat keranjang belanja Anda',
            onTap: () {
              // Navigasi ke halaman keranjang belanja
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.card_giftcard,
            title: 'Tukar Poin',
            subtitle: 'Tukar poin dengan hadiah menarik',
            onTap: () {
              // Navigasi ke halaman pengaturan
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green.shade600),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
