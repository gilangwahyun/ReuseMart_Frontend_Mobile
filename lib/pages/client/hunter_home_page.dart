import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../api/auth_api.dart';
import '../../api/pegawai_api.dart';
import '../../api/komisi_pegawai_api.dart';
import '../../models/komisi_pegawai_model.dart';
import '../../models/pegawai_model.dart';
import '../../models/user_profile_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import 'komisi_detail_page.dart';

class HunterHomePage extends StatefulWidget {
  const HunterHomePage({super.key});

  @override
  State<HunterHomePage> createState() => _HunterHomePageState();
}

class _HunterHomePageState extends State<HunterHomePage> {
  final AuthApi _authApi = AuthApi();
  final PegawaiApi _pegawaiApi = PegawaiApi();
  final KomisiPegawaiApi _komisiPegawaiApi = KomisiPegawaiApi();

  UserProfileModel? _userProfile;
  PegawaiModel? _pegawaiProfile;
  List<KomisiPegawaiModel> _komisiList = [];
  double _totalKomisi = 0;
  bool _isLoading = true;
  String? _errorMessage;

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
      // Check login status
      final isLoggedIn = await _authApi.isLoggedIn();

      if (!isLoggedIn) {
        if (mounted) {
          AppRoutes.navigateAndClear(context, AppRoutes.login);
        }
        return;
      }

      // Get user profile
      final userData = await _authApi.getUserData();
      if (userData == null) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final userId = userData['id_user'];

      // Get pegawai data
      final pegawaiData = await _pegawaiApi.getPegawaiByUserId(userId);
      if (pegawaiData == null) {
        setState(() {
          _errorMessage = 'Pegawai data not found';
          _isLoading = false;
        });
        return;
      }

      // Save the pegawai model
      final pegawai = PegawaiModel.fromJson(pegawaiData);
      setState(() {
        _pegawaiProfile = pegawai;
      });

      // Get user profile
      final profile = await LocalStorage.getProfile();
      setState(() {
        _userProfile = profile;
      });

      // Load komisi for this hunter
      await _loadKomisiData(pegawai.idPegawai);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadKomisiData(int pegawaiId) async {
    try {
      // Get komisi data
      final komisiList = await _komisiPegawaiApi.getKomisiByPegawai(pegawaiId);
      
      // Calculate total komisi
      final totalKomisi = await _komisiPegawaiApi.getTotalKomisiPegawai(pegawaiId);

      setState(() {
        _komisiList = komisiList;
        _totalKomisi = totalKomisi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load commission data: $e';
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

    if (_errorMessage != null) {
      return Center(
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
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildWelcomeBanner(), _buildKomisiDetailsSection()],
        ),
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
            'Welcome,',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            _pegawaiProfile?.namaPegawai ?? 'Hunter',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Job Title',
                  value: _pegawaiProfile?.jabatan?['nama_jabatan'] ?? 'Hunter',
                  icon: Icons.work,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Jumlah Komisi',
                  value: 'Rp ${_formatRupiah(_totalKomisi)}',
                  icon: Icons.monetization_on,
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

  Widget _buildKomisiDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History Komisi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _komisiList.isEmpty
              ? _buildEmptyKomisiState()
              : Column(
                children:
                    _komisiList
                        .map((komisi) => _buildKomisiItem(komisi))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyKomisiState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada komisi',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildKomisiItem(KomisiPegawaiModel komisi) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KomisiDetailPage(
              komisiId: komisi.idKomisiPegawai,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaksi #${komisi.idTransaksi}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Text(
                      'Rp ${_formatRupiah(komisi.jumlahKomisi)}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (komisi.transaksi != null && komisi.transaksi!.containsKey('tanggal_transaksi'))
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tanggal: ${_formatDate(komisi.transaksi!['tanggal_transaksi'])}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (komisi.transaksi != null && 
                  komisi.transaksi!.containsKey('alamat') && 
                  komisi.transaksi!['alamat'] != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        komisi.transaksi!['alamat']['alamat_lengkap'] ??
                            'Tidak ada alamat',
                        style: TextStyle(color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
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
