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
  final bool isEmbedded;

  const PenitipProfilePage({super.key, this.isEmbedded = true});

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
  int _selectedNavIndex = 1;
  bool _isPersonalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadTopSellerBadge();
    setState(() {
      _isLoading = false;
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
          // Panggil _loadTopSellerBadge setelah data penitip tersedia
          await _loadTopSellerBadge();
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
    print('\n=== DEBUG BADGE START ===');

    // Cek apakah ada data penitip
    if (_userProfile?.penitip == null) {
      print('DEBUG BADGE: Penitip tidak ditemukan di userProfile');
      print('=== DEBUG BADGE END ===\n');
      return;
    }

    final idPenitip = _userProfile!.penitip!.idPenitip.toString();
    print('DEBUG BADGE: Mencoba memuat badge untuk penitip ID: $idPenitip');

    try {
      final response = await _badgeApi.getTopSeller(idPenitip);
      print('DEBUG BADGE: Response dari API: $response');

      if (response != null && response['data'] != null) {
        final badgeData = response['data'];
        print('DEBUG BADGE: Data badge ditemukan');
        print('DEBUG BADGE: Nama Badge: ${badgeData['nama_badge']}');
        print('DEBUG BADGE: Deskripsi: ${badgeData['deskripsi']}');
        if (badgeData['penitip'] != null) {
          print(
            'DEBUG BADGE: Data Penitip: ${badgeData['penitip']['nama_penitip']}',
          );
        }

        setState(() {
          _topSellerBadge = BadgeModel.fromJson(badgeData);
        });
        print(
          'DEBUG BADGE: Badge berhasil disimpan ke state: ${_topSellerBadge?.namaBadge}',
        );
      } else {
        print('DEBUG BADGE: Tidak ada badge untuk penitip ini');
        setState(() {
          _topSellerBadge = null;
        });
      }
    } catch (e) {
      print('DEBUG BADGE: Error saat memuat badge: $e');
      setState(() {
        _topSellerBadge = null;
      });
    }
    print('=== DEBUG BADGE END ===\n');
  }

  void _onNavBarTapped(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    // Jika halaman ini disematkan dalam container, tidak perlu navigasi antar tab
    if (widget.isEmbedded) return;

    // Hanya navigasi jika tidak disematkan dalam container
    switch (index) {
      case 0:
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
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
        ),
      );
    }

    // Jika tidak ada data profil
    if (_userProfile == null || _userProfile!.penitip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Data profil tidak ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan coba lagi atau hubungi administrator',
              textAlign: TextAlign.center,
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
      );
    }

    // Jika halaman ini tidak disematkan (standalone), gunakan Scaffold dengan AppBar
    if (!widget.isEmbedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          backgroundColor: Colors.green.shade600,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
          ],
        ),
        body: _buildProfileContent(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: _onNavBarTapped,
          selectedItemColor: Colors.green.shade700,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    }

    // Jika halaman ini disematkan (embedded), hanya tampilkan konten tanpa Scaffold
    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            if (_topSellerBadge != null) _buildBadgeCard(),
            _buildStatsRow(),
            _buildPersonalInfoSection(),
            _buildProfileMenu(),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Anda belum login',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login untuk melihat profil Anda',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 3),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.green.shade50,
              child: Icon(Icons.person, size: 50, color: Colors.green.shade700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.name ?? 'Nama Penitip',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _userProfile?.user.email ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_userProfile?.phone.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userProfile!.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Text(
                    _topSellerBadge?.namaBadge ?? 'TOP SELLER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.white, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _topSellerBadge?.deskripsi ?? 'Penitip dengan performa terbaik',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num value = number is int ? number.toDouble() : number;

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (_userProfile?.penitip?.saldo != null)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saldo',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatNumber(_userProfile?.penitip?.saldo)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_userProfile?.poin != null && _userProfile!.poin > 0) ...[
            if (_userProfile?.penitip?.saldo != null) const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Poin',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatNumber(_userProfile?.poin),
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    if (_userProfile?.penitip == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    'Nama Lengkap',
                    _userProfile!.penitip!.namaPenitip,
                  ),
                  _buildInfoItem(
                    'No. Telepon',
                    _userProfile!.penitip!.noTelepon,
                  ),
                  _buildInfoItem('Alamat', _userProfile!.penitip!.alamat),
                  _buildInfoItem('NIK', _userProfile!.penitip!.nik),
                  _buildInfoItem('Email', _userProfile!.user.email),
                  _buildInfoItem('Status', 'Penitip Aktif'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory, color: Colors.green.shade600),
            ),
            title: const Text(
              'Barang Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Lihat semua barang penitipan Anda',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
            onTap: () {
              AppRoutes.navigateTo(context, AppRoutes.penitipBarang);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: () async {
          // Show confirmation dialog
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya, Keluar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
          );

          if (shouldLogout == true) {
            await _authApi.logout();
            if (mounted) {
              AppRoutes.navigateAndClear(context, AppRoutes.login);
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
