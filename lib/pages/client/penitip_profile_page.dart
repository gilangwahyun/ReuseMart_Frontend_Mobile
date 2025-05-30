import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../api/barang_api.dart';
import '../../api/penitip_api.dart';
import '../../components/custom_button.dart';
import '../../models/user_profile_model.dart';
import '../../models/barang_penitipan_model.dart';
import '../../models/penitip_model.dart';
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
  final BarangApi _barangApi = BarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  int _selectedNavIndex = 1; // 1 untuk halaman profile, 0 untuk home

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

      // Coba dapatkan data user dari local storage terlebih dahulu
      final userData = await LocalStorage.getUser();
      if (userData != null) {
        print(
          "Data user ditemukan. ID: ${userData.idUser}, Role: ${userData.role}",
        );
      } else {
        print("Data user tidak ditemukan di local storage");
      }

      // Coba dapatkan data profil dari local storage
      final localProfile = await LocalStorage.getProfile();
      if (localProfile != null) {
        print("Data profil ditemukan di local storage");
        if (localProfile.penitip != null) {
          print(
            "Data penitip tersedia. ID Penitip: ${localProfile.penitip!.idPenitip}",
          );
        } else {
          print("Data penitip tidak tersedia di profil lokal");
        }

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
          // Ambil data profil lengkap dari API
          print("Mencoba mendapatkan profil dari API...");
          final apiProfile = await _userApi.getProfile();

          if (apiProfile.penitip != null) {
            print(
              "API berhasil mendapatkan data penitip dengan ID: ${apiProfile.penitip!.idPenitip}",
            );

            setState(() {
              _userProfile = apiProfile;
            });

            // Pastikan menyimpan id_penitip untuk digunakan nanti
            await LocalStorage.savePenitipId(
              apiProfile.penitip!.idPenitip.toString(),
            );
            print(
              "ID penitip disimpan ke local storage: ${apiProfile.penitip!.idPenitip}",
            );

            // Jika diperlukan, ambil data detail penitip tambahan
            try {
              print(
                "Mencoba ambil data detail penitip dengan ID: ${apiProfile.penitip!.idPenitip}",
              );
              final penitipData = await _penitipApi.getPenitipById(
                apiProfile.penitip!.idPenitip,
              );
              print('Data penitip berhasil diambil: Detail tersedia');
            } catch (e) {
              print('Error mengambil data detail penitip: $e');
            }
          } else {
            print("API tidak mengembalikan data penitip dalam profil");
            // Jika API tidak mengembalikan data penitip, coba ambil langsung dengan user ID
            if (userData != null) {
              try {
                print(
                  "Mencoba ambil data penitip langsung dengan user ID: ${userData.idUser}",
                );
                final penitipResponse = await _penitipApi.getPenitipByUserId(
                  userData.idUser,
                );

                if (penitipResponse != null &&
                    penitipResponse['success'] == true) {
                  final penitipData = penitipResponse['data'];
                  print(
                    "Berhasil mendapatkan data penitip langsung. ID Penitip: ${penitipData['id_penitip']}",
                  );

                  // Perbarui profil lokal jika data penitip ditemukan
                  if (_userProfile != null && penitipData != null) {
                    try {
                      final penitip = PenitipModel.fromJson(penitipData);
                      final updatedProfile = UserProfileModel(
                        user: _userProfile!.user,
                        penitip: penitip,
                      );

                      setState(() {
                        _userProfile = updatedProfile;
                      });

                      // Update di local storage
                      await LocalStorage.saveProfile(updatedProfile);
                      await LocalStorage.savePenitipId(
                        penitip.idPenitip.toString(),
                      );
                      print(
                        "Profil berhasil diperbarui dengan data penitip langsung",
                      );
                    } catch (e) {
                      print("Error memperbarui profil dengan data penitip: $e");
                    }
                  }
                } else {
                  print(
                    "Gagal mendapatkan data penitip langsung: ${penitipResponse}",
                  );
                }
              } catch (e) {
                print("Error saat mengambil data penitip langsung: $e");
              }
            }
          }

          // Simpan data terbaru ke local storage
          await LocalStorage.saveProfile(_userProfile!);
          print('Data profil diperbarui dari API dan disimpan');
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
          print("Tidak ada status login dan tidak ada data lokal");
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
      // Coba logout ke API
      await _authApi.logout();

      // Hapus semua data lokal menggunakan method yang lebih lengkap
      await _authApi.clearAllCacheData();

      if (mounted) {
        AppRoutes.navigateAndClear(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');

      // Tetap hapus semua data dari local storage meskipun API logout gagal
      await _authApi.clearAllCacheData();

      if (mounted) {
        AppRoutes.navigateAndClear(context, AppRoutes.login);
      }
    }
  }

  void _onNavBarTapped(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigasi ke Home Penitip
        AppRoutes.navigateAndReplace(context, AppRoutes.penitipHome);
        break;
      case 1:
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
            _userProfile?.name ?? 'Nama Penitip',
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
          if (_userProfile?.user.role == 'Penitip' &&
              _userProfile?.penitip != null) ...[
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
                      Icon(Icons.store, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Penitip',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_userProfile!.penitip?.saldo != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rp ${_userProfile!.penitip!.saldo}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            icon: Icons.inventory,
            title: 'Barang Saya',
            subtitle: 'Lihat semua barang penitipan Anda',
            onTap: () {
              // Navigasi ke halaman daftar penitipan barang
              AppRoutes.navigateTo(context, AppRoutes.penitipBarang);
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Riwayat Penitipan',
            subtitle: 'Lihat riwayat penitipan barang Anda',
            onTap: () {
              // Navigasi ke halaman riwayat penitipan
              AppRoutes.navigateTo(context, AppRoutes.riwayatPenitipan);
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.account_circle,
            title: 'Edit Profil',
            subtitle: 'Perbarui data profil Anda',
            onTap: () {
              // Navigasi ke halaman edit profil
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.payments,
            title: 'Pendapatan',
            subtitle: 'Lihat pendapatan dari penjualan barang',
            onTap: () {
              // Navigasi ke halaman pendapatan
              AppRoutes.navigateTo(context, AppRoutes.pendapatanPenitip);
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.delete_sweep,
            title: 'Bersihkan Cache',
            subtitle: 'Hapus data cache aplikasi (Force Logout)',
            onTap: () {
              _showForceLogoutDialog();
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

  void _showForceLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bersihkan Cache'),
            content: const Text(
              'Ini akan menghapus semua data tersimpan dan memaksa logout. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Gunakan method forceLogout dari AuthApi
                    await _authApi.forceLogout();

                    if (mounted) {
                      AppRoutes.navigateAndClear(context, AppRoutes.login);
                    }
                  } catch (e) {
                    print('Error saat force logout: $e');

                    // Fallback jika gagal
                    await LocalStorage.clearAllData();

                    if (mounted) {
                      AppRoutes.navigateAndClear(context, AppRoutes.login);
                    }
                  }
                },
                child: const Text(
                  'Hapus Cache',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
