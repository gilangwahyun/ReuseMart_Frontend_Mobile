import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../api/barang_api.dart';
import '../../api/penitip_api.dart';
import '../../api/badge_api.dart';
import '../../models/user_profile_model.dart';
import '../../models/barang_penitipan_model.dart';
import '../../models/penitip_model.dart';
import '../../models/badge_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import 'dart:convert';

class PenitipProfilePage extends StatefulWidget {
  const PenitipProfilePage({super.key});

  @override
  State<PenitipProfilePage> createState() => _PenitipProfilePageState();
}

class _PenitipProfilePageState extends State<PenitipProfilePage> {
  UserProfileModel? _userProfile;
  BadgeModel? _topSellerBadge;
  bool _isLoading = true;
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi();
  final BarangApi _barangApi = BarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  final BadgeApi _badgeApi = BadgeApi();
  int _selectedNavIndex = 1; // 1 untuk halaman profile, 0 untuk home

  // Tambahkan state untuk expandable sections
  bool _isPersonalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTopSellerBadge();

    // Tambahkan listener untuk perubahan fokus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Periksa dan muat ulang data saat halaman mendapatkan fokus
        final focusScope = FocusScope.of(context);
        focusScope.addListener(() {
          if (focusScope.hasFocus && mounted) {
            _loadUserData();
            _loadTopSellerBadge();
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

      // PERBAIKAN: Lakukan pengambilan data langsung dari local storage terlebih dahulu
      final userData = await LocalStorage.getUser();
      if (userData != null) {
        print(
          "Data user ditemukan. ID: ${userData.idUser}, Role: ${userData.role}",
        );

        // PERBAIKAN: Cek dan tampilkan token
        final token = await LocalStorage.getToken();
        print("Token tersedia: ${token != null && token.isNotEmpty}");
        if (token != null) {
          print("Token length: ${token.length}");
        }
      } else {
        print("Data user tidak ditemukan di local storage");
      }

      // PERBAIKAN: Langsung coba ambil profil dari API terlebih dahulu jika login
      if (isLoggedIn) {
        try {
          print("User terdeteksi login, mencoba ambil data profil dari API...");
          final apiProfile = await _userApi.getProfile();

          if (apiProfile != null) {
            print("Profil berhasil diambil dari API");

            // PERBAIKAN: Debug isi profil
            print("Data profil: ${jsonEncode(apiProfile.toJson())}");

            if (apiProfile.penitip != null) {
              print(
                "Data penitip tersedia dari API: ${apiProfile.penitip!.idPenitip}",
              );

              // PERBAIKAN: Set state terlebih dahulu
              setState(() {
                _userProfile = apiProfile;
              });

              // Simpan ke local storage
              await LocalStorage.saveProfile(apiProfile);
              await LocalStorage.savePenitipId(
                apiProfile.penitip!.idPenitip.toString(),
              );
              print("Data profil dari API disimpan ke local storage");
            } else {
              print("Data penitip tidak tersedia dalam profil dari API");
            }
          }
        } catch (e) {
          print("Error mengambil profil dari API: $e");
        }
      }

      // PERBAIKAN: Jika gagal ambil dari API atau tidak login, coba ambil dari local storage
      if (_userProfile == null) {
        final localProfile = await LocalStorage.getProfile();
        if (localProfile != null) {
          print("Menggunakan data profil dari local storage");
          print("Data profil local: ${jsonEncode(localProfile.toJson())}");

          if (localProfile.penitip != null) {
            print(
              "Data penitip tersedia dari local storage: ${localProfile.penitip!.idPenitip}",
            );
          } else {
            print("Data penitip TIDAK tersedia di local storage");
          }

          setState(() {
            _userProfile = localProfile;
          });
        } else {
          print("Tidak ada data profil di local storage");
        }
      }

      // PERBAIKAN: Jika masih tidak ada data penitip, coba ambil langsung dengan ID user
      if (_userProfile != null &&
          _userProfile!.penitip == null &&
          userData != null) {
        try {
          print(
            "Mencoba ambil data penitip langsung dengan ID user: ${userData.idUser}",
          );
          final penitipResponse = await _penitipApi.getPenitipByUserId(
            userData.idUser,
          );

          if (penitipResponse != null && penitipResponse['success'] == true) {
            print("Data penitip ditemukan dengan format success:true");
            final penitipData = penitipResponse['data'];

            if (penitipData != null) {
              // Debug
              print("Parsing PenitipModel dari: ${penitipData.keys.toList()}");

              try {
                final penitip = PenitipModel.fromJson(penitipData);

                // PERBAIKAN: Buat objek UserProfileModel baru dengan data lengkap
                final updatedProfile = UserProfileModel(
                  user: _userProfile!.user,
                  penitip: penitip,
                );

                setState(() {
                  _userProfile = updatedProfile;
                });

                await LocalStorage.saveProfile(updatedProfile);
                await LocalStorage.savePenitipId(penitip.idPenitip.toString());
                print(
                  "Profil berhasil diperbarui dengan data penitip langsung",
                );
              } catch (e) {
                print("Error saat parsing model penitip: $e");
                // PERBAIKAN: Coba tampilkan data mentahnya untuk debugging
                print("Raw penitip data: $penitipData");
              }
            }
          } else {
            print("Gagal mendapatkan data penitip: ${penitipResponse}");
          }
        } catch (e) {
          print("Error saat ambil data penitip: $e");
        }
      }

      // PERBAIKAN: Periksa hasil akhir
      if (_userProfile != null) {
        print("_userProfile akhir: ${_userProfile!.user.role}");
        if (_userProfile!.penitip != null) {
          print(
            "Data penitip tersedia. ID: ${_userProfile!.penitip!.idPenitip}",
          );
        } else {
          print("Data penitip TIDAK tersedia di _userProfile akhir");
        }
      } else {
        print("_userProfile masih NULL setelah semua proses");
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

  Future<void> _loadTopSellerBadge() async {
    if (_userProfile?.penitip == null) return;

    try {
      final response = await _badgeApi.getTopSeller();
      if (response != null &&
          response['data'] != null &&
          response['data']['id_penitip'] == _userProfile?.penitip?.idPenitip) {
        setState(() {
          _topSellerBadge = BadgeModel.fromJson(response['data']);
        });
      }
    } catch (e) {
      print('Error loading top seller badge: $e');
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
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade200,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
              if (_topSellerBadge != null)
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
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
          if (_topSellerBadge != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade400),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOP SELLER',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _topSellerBadge?.deskripsi ?? '',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  // Widget untuk menampilkan informasi pribadi dalam section yang bisa di-expand
  Widget _buildPersonalInfoSection() {
    if (_userProfile?.penitip == null) {
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
          // Header yang bisa di-klik untuk expand/collapse
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

          // Content yang bisa di-expand/collapse
          if (_isPersonalInfoExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    'Nama Lengkap',
                    _userProfile!.penitip!.namaPenitip,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    'No. Telepon',
                    _userProfile!.penitip!.noTelepon,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Alamat', _userProfile!.penitip!.alamat),
                  const SizedBox(height: 12),
                  _buildInfoItem('NIK', _userProfile!.penitip!.nik),
                  const SizedBox(height: 12),
                  _buildInfoItem('Email', _userProfile!.user.email),
                  const SizedBox(height: 12),
                  _buildInfoItem('Status', 'Penitip Aktif'),
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
            icon: Icons.inventory,
            title: 'Barang Saya',
            subtitle: 'Lihat semua barang penitipan Anda',
            onTap: () {
              // Navigasi ke halaman daftar penitipan barang
              AppRoutes.navigateTo(context, AppRoutes.penitipBarang);
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

  // Widget untuk item informasi pribadi
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
