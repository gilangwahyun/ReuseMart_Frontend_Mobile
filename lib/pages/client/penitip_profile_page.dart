import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../components/custom_button.dart';
import '../../components/layouts/base_layout.dart';
import '../../models/user_profile_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';

class PenitipProfilePage extends StatefulWidget {
  const PenitipProfilePage({super.key});

  @override
  State<PenitipProfilePage> createState() => _PenitipProfilePageState();
}

class _PenitipProfilePageState extends State<PenitipProfilePage> {
  UserProfileModel? _userProfile;
  bool _isLoading = true;
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Coba dapatkan data dari local storage terlebih dahulu
      final localProfile = await LocalStorage.getProfile();
      if (localProfile != null) {
        setState(() {
          _userProfile = localProfile;
        });
      }

      // Periksa status login
      final isLoggedIn = await _authApi.isLoggedIn();
      if (isLoggedIn) {
        // Jika sudah login, perbarui data dari API
        final apiProfile = await _userApi.getProfile();

        setState(() {
          _userProfile = apiProfile;
        });

        // Simpan data terbaru ke local storage
        await LocalStorage.saveProfile(apiProfile);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Tetap gunakan data dari local storage jika terjadi error
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
      if (mounted) {
        AppRoutes.navigateAndClear(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Tetap hapus data dari local storage meskipun API logout gagal
      await LocalStorage.clearAuthData();

      if (mounted) {
        AppRoutes.navigateAndClear(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BaseLayout(
        title: 'Profil Penitip',
        showBackButton: true,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseLayout(
      title: 'Profil Penitip',
      showBackButton: true,
      body:
          _userProfile == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Anda belum login'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        AppRoutes.navigateAndClear(context, AppRoutes.login);
                      },
                      child: const Text('Login Sekarang'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const Divider(),
                    _buildProfileMenu(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomButton(
                        text: 'Logout',
                        onPressed: () {
                          _showLogoutDialog();
                        },
                        backgroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.name ?? 'Nama Penitip',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.user.email ?? 'email@example.com',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_userProfile?.phone.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.phone,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
          if (_userProfile?.address != null) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.address!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
          if (_userProfile?.user.role == 'Penitip' &&
              _userProfile?.penitip != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Penitip',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                if (_userProfile!.penitip?.saldo != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Saldo: Rp${_userProfile!.penitip!.saldo!}',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                ],
                if (_userProfile!.poin > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Poin: ${_userProfile!.poin}',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person,
          title: 'Edit Profil',
          onTap: () {
            // Navigasi ke halaman edit profil
          },
        ),
        _buildMenuItem(
          icon: Icons.inventory,
          title: 'Barang Saya',
          onTap: () {
            // Navigasi ke halaman barang penitip
          },
        ),
        _buildMenuItem(
          icon: Icons.add_box,
          title: 'Titip Barang',
          onTap: () {
            // Navigasi ke halaman penitipan barang
          },
        ),
        _buildMenuItem(
          icon: Icons.history,
          title: 'Riwayat Penitipan',
          onTap: () {
            // Navigasi ke halaman riwayat penitipan
          },
        ),
        _buildMenuItem(
          icon: Icons.payments,
          title: 'Pendapatan',
          onTap: () {
            // Navigasi ke halaman pendapatan
          },
        ),
        _buildMenuItem(
          icon: Icons.analytics,
          title: 'Statistik Penjualan',
          onTap: () {
            // Navigasi ke halaman statistik
          },
        ),
        _buildMenuItem(
          icon: Icons.card_giftcard,
          title: 'Poin Reward',
          onTap: () {
            // Navigasi ke halaman poin reward
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Pengaturan',
          onTap: () {
            // Navigasi ke halaman pengaturan
          },
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Bantuan & Dukungan',
          onTap: () {
            // Navigasi ke halaman bantuan
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
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
