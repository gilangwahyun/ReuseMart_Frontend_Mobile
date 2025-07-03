import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../api/merchandise_api.dart';
import '../../api/klaim_merchandise_api.dart';
import '../../api/user_api.dart';
import '../../models/merchandise_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/pembeli_model.dart';
import '../../utils/local_storage.dart';

class MerchandisePage extends StatefulWidget {
  const MerchandisePage({super.key});

  @override
  State<MerchandisePage> createState() => _MerchandisePageState();
}

class _MerchandisePageState extends State<MerchandisePage> {
  final MerchandiseApi _merchandiseApi = MerchandiseApi();
  final KlaimMerchandiseApi _klaimMerchandiseApi = KlaimMerchandiseApi();
  final UserApi _userApi = UserApi();

  List<Merchandise> _merchandiseList = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserProfileModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user profile first
      final userProfile = await LocalStorage.getProfile();
      if (userProfile != null) {
        setState(() {
          _userProfile = userProfile;
        });

        // If we have a local profile, try to get the updated version from the API
        try {
          final apiProfile = await _userApi.getProfile();
          setState(() {
            _userProfile = apiProfile;
          });
          await LocalStorage.saveProfile(apiProfile);
        } catch (e) {
          // If API call fails, we'll still use the local profile
          print('Failed to update profile from API: $e');
        }
      } else {
        // If no local profile, try to get from API
        try {
          final apiProfile = await _userApi.getProfile();
          setState(() {
            _userProfile = apiProfile;
          });
          await LocalStorage.saveProfile(apiProfile);
        } catch (e) {
          setState(() {
            _errorMessage = 'Login required to view merchandise';
          });
          return;
        }
      }

      // Load merchandise
      final merchandiseList = await _merchandiseApi.getAllMerchandise();
      setState(() {
        _merchandiseList = merchandiseList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load merchandise: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _redeemMerchandise(Merchandise merchandise) async {
    developer.log('===== MEMULAI PROSES PENUKARAN MERCHANDISE =====');

    if (_userProfile == null || _userProfile!.pembeli == null) {
      developer.log('ERROR: User profile atau data pembeli tidak tersedia');
      _showErrorDialog('Login diperlukan');
      return;
    }

    developer.log('ID Pembeli: ${_userProfile!.pembeli!.idPembeli}');
    developer.log('ID User: ${_userProfile!.user.idUser}');
    developer.log('Email: ${_userProfile!.user.email}');

    if (_userProfile!.poin < merchandise.jumlahPoin) {
      developer.log(
        'ERROR: Poin tidak mencukupi (${_userProfile!.poin} < ${merchandise.jumlahPoin})',
      );
      _showErrorDialog('Poin tidak mencukupi');
      return;
    }

    if (merchandise.stok <= 0) {
      developer.log('ERROR: Stok merchandise habis');
      _showErrorDialog('Stok habis');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      developer.log('===== MENCOBA MENUKAR MERCHANDISE =====');
      developer.log('ID Pembeli: ${_userProfile!.pembeli!.idPembeli}');
      developer.log('ID Merchandise: ${merchandise.idMerchandise}');
      developer.log('Nama Merchandise: ${merchandise.namaMerchandise}');
      developer.log('Poin yang dibutuhkan: ${merchandise.jumlahPoin}');
      developer.log('Poin pengguna saat ini: ${_userProfile!.poin}');
      developer.log('Stok tersedia: ${merchandise.stok}');

      // Tampilkan proses penukaran kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sedang memproses penukaran ${merchandise.namaMerchandise}...',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      // Panggil API untuk membuat klaim
      developer.log('Memanggil API createKlaim...');
      final berhasil = await _klaimMerchandiseApi.createKlaim(
        _userProfile!.pembeli!.idPembeli,
        merchandise.idMerchandise,
      );

      developer.log('Hasil API createKlaim: $berhasil');

      if (!berhasil) {
        developer.log('ERROR: API mengembalikan status gagal');
        throw Exception('Gagal menukar merchandise');
      }

      developer.log('Penukaran berhasil dilakukan');

      // Refresh data dari server
      developer.log('Memuat ulang data...');
      await _loadData();
      developer.log('Data berhasil dimuat ulang');

      // Show success message
      _showSuccessDialog(
        'Penukaran poin dengan ${merchandise.namaMerchandise} berhasil!',
      );
    } catch (e) {
      developer.log('ERROR saat menukar merchandise: $e');

      // Coba refresh data meskipun gagal
      developer.log('Mencoba memuat ulang data setelah error...');
      try {
        await _loadData();
        developer.log('Data berhasil dimuat ulang setelah error');
      } catch (refreshError) {
        developer.log('Gagal memuat ulang data: $refreshError');
      }

      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Gagal menukar merchandise: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              if (message.contains('Gagal menukar merchandise'))
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _tryAlternativeRedemption();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                const Text(
                  'Catatan: Merchandise dapat diambil di lokasi ReuseMart.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Metode untuk mencoba penukaran dengan metode alternatif
  Future<void> _tryAlternativeRedemption() async {
    if (_userProfile == null || _userProfile!.pembeli == null) {
      _showErrorDialog('Login diperlukan');
      return;
    }

    // Ambil merchandise yang terakhir dicoba
    final merchandise = _merchandiseList.firstWhere(
      (m) => _userProfile!.poin >= m.jumlahPoin && m.stok > 0,
      orElse: () => _merchandiseList.first,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log(
        '===== MENCOBA MENUKAR MERCHANDISE DENGAN METODE ALTERNATIF =====',
      );
      developer.log('ID Pembeli: ${_userProfile!.pembeli!.idPembeli}');
      developer.log('ID Merchandise: ${merchandise.idMerchandise}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mencoba ulang penukaran ${merchandise.namaMerchandise}...',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      // Gunakan metode alternatif di API
      final directHttpSuccess = await _klaimMerchandiseApi
          .createKlaimWithDirectHttp(
            _userProfile!.pembeli!.idPembeli,
            merchandise.idMerchandise,
          );

      if (directHttpSuccess) {
        developer.log('Penukaran dengan metode alternatif berhasil');
        await _loadData();
        _showSuccessDialog(
          'Penukaran poin dengan ${merchandise.namaMerchandise} berhasil!',
        );
      } else {
        throw Exception('Gagal menukar merchandise dengan metode alternatif');
      }
    } catch (e) {
      developer.log('ERROR pada metode alternatif: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Semua metode gagal: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukar Poin'),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Points display
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.amber.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Poin Anda: ${_userProfile?.poin ?? 0}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Merchandise list
                  Expanded(
                    child:
                        _merchandiseList.isEmpty
                            ? const Center(
                              child: Text('No merchandise available'),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _merchandiseList.length,
                              itemBuilder: (context, index) {
                                final merchandise = _merchandiseList[index];
                                final canRedeem =
                                    _userProfile != null &&
                                    _userProfile!.poin >=
                                        merchandise.jumlahPoin &&
                                    merchandise.stok > 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          merchandise.namaMerchandise,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.amber.shade400,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color:
                                                        Colors.amber.shade700,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${merchandise.jumlahPoin} Poin',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.amber.shade800,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.blue.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.inventory_2,
                                                    color: Colors.blue.shade700,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Stok: ${merchandise.stok}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed:
                                                canRedeem
                                                    ? () => _redeemMerchandise(
                                                      merchandise,
                                                    )
                                                    : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              disabledBackgroundColor:
                                                  Colors.grey.shade300,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              canRedeem
                                                  ? 'Tukarkan'
                                                  : merchandise.stok <= 0
                                                  ? 'Stok Habis'
                                                  : 'Poin Tidak Cukup',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    canRedeem
                                                        ? Colors.white
                                                        : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
