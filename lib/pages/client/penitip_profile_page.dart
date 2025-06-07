import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../api/barang_api.dart';
import '../../api/penitip_api.dart';
import '../../models/user_profile_model.dart';
import '../../models/barang_penitipan_model.dart';
import '../../models/penitip_model.dart';
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
  bool _isLoading = true;
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi();
  final BarangApi _barangApi = BarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  int _selectedNavIndex = 1; // 1 untuk halaman profile, 0 untuk home

  // Tambahkan state untuk expandable sections
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(),
          _buildProfileInfo(),
          _buildLogoutButton(),
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

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.person,
            title: 'Nama',
            value: _userProfile!.penitip!.namaPenitip,
          ),
          _buildInfoItem(
            icon: Icons.email,
            title: 'Email',
            value: _userProfile?.user.email ?? '-',
          ),
          _buildInfoItem(
            icon: Icons.phone,
            title: 'Telepon',
            value: _userProfile!.penitip!.noTelepon,
          ),
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Alamat',
            value: _userProfile!.penitip!.alamat,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
            builder: (context) => AlertDialog(
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
