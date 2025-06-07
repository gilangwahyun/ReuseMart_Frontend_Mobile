import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../components/custom_button.dart';
import '../../models/user_profile_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import 'merchandise_page.dart';

class PembeliProfilePage extends StatefulWidget {
  final bool isEmbedded;
  
  const PembeliProfilePage({super.key, this.isEmbedded = false});

  @override
  State<PembeliProfilePage> createState() => _PembeliProfilePageState();
}

class _PembeliProfilePageState extends State<PembeliProfilePage> {
  UserProfileModel? _userProfile;
  bool _isLoading = true;
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi();
  int _selectedNavIndex = 3; // 3 untuk halaman profile
  String? _error;

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

      // Coba dapatkan data dari local storage
      final localProfile = await LocalStorage.getProfile();

      if (localProfile != null) {
        // Gunakan data lokal jika tersedia
        setState(() {
          _userProfile = localProfile;
        });

        if (!isLoggedIn) {
          // Jika data lokal ada tapi token tidak ada, coba refresh token
          try {
            // Simpan token dari data local jika ada
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
          final apiProfile = await _userApi.getProfile();

          setState(() {
            _userProfile = apiProfile;
          });

          // Simpan data terbaru ke local storage
          await LocalStorage.saveProfile(apiProfile);
          print('Data profil diperbarui dari API');
        } catch (e) {
          print('Error saat mengambil profil dari API: $e');
          // Jika gagal mengambil dari API tapi masih ada data lokal,
          // tetap gunakan data lokal dan jangan tampilkan error
          if (_userProfile == null) {
            // Hanya tampilkan error jika tidak ada data lokal
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
      } else {
        // Jika tidak login dan tidak ada data lokal, kosongkan profil
        if (_userProfile == null) {
          setState(() {
            _userProfile = null;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Tampilkan pesan error jika terjadi kesalahan
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

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authApi.logout();
      
      // Clear any local user data
      await LocalStorage.clearAuthData();
      
      // Navigate to login page
      if (mounted) {
        // Use navigateAndClear to remove all previous routes and set a named route
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
          arguments: {'source': 'logout'},
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Even if API logout fails, still clear local data and navigate to login
      await LocalStorage.clearAuthData();

      if (mounted) {
        // Use navigateAndClear to remove all previous routes and set a named route
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
          arguments: {'source': 'logout'},
        );
      }
    }
  }

  void _onNavBarTapped(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    // When embedded in container, we don't need navigation between tabs
    if (widget.isEmbedded) return;

    // Only navigate if not embedded in container
    AppRoutes.navigateAndReplace(context, AppRoutes.pembeliContainer);
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.isEmbedded instead of checking route
    final bool isEmbedded = widget.isEmbedded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _userProfile == null
                  ? const Center(
                      child: Text('Tidak ada data profil'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildProfileMenu(),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: CustomButton(
                              text: 'Logout',
                              onPressed: () {
                                _showLogoutDialog();
                              },
                              backgroundColor: Colors.red.shade600,
                              textColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
      // Only show bottom navigation when not embedded in container
      bottomNavigationBar: isEmbedded ? null : BottomNavigationBar(
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
                      Icon(Icons.star, color: Colors.amber.shade700, size: 18),
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
              // Untuk sementara tidak ada navigasi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur ini sedang dalam pengembangan'),
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
              print("Tukar Poin clicked, navigating to merchandise");
              
              // Use regular Navigator.push when embedded in a container
              // This allows navigation within the nested navigator
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MerchandisePage()),
              );
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
