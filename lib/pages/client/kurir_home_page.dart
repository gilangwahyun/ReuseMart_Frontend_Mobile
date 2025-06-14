import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/jadwal_api.dart';
import '../../api/pegawai_api.dart';
import '../../api/user_api.dart';
import '../../models/jadwal_model.dart';
import '../../models/pegawai_model.dart';
import '../../models/user_profile_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/local_storage.dart';
import '../../widgets/notification_icon.dart';

class KurirHomePage extends StatefulWidget {
  const KurirHomePage({super.key});

  @override
  State<KurirHomePage> createState() => _KurirHomePageState();
}

class _KurirHomePageState extends State<KurirHomePage> {
  final UserApi _userApi = UserApi();
  final AuthApi _authApi = AuthApi();
  final PegawaiApi _pegawaiApi = PegawaiApi();
  final JadwalApi _jadwalApi = JadwalApi();

  UserProfileModel? _userProfile;
  PegawaiModel? _pegawaiProfile;
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 0; // 0 for home

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

      // Load jadwal for this courier
      await _loadJadwalData(pegawai.idPegawai);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadJadwalData(int pegawaiId) async {
    try {
      final jadwalData = await _jadwalApi.getJadwalByPegawai(pegawaiId);

      if (jadwalData is List) {
        final jadwals =
            jadwalData.map((item) => JadwalModel.fromJson(item)).toList();

        setState(() {
          _jadwalList = jadwals;
          _isLoading = false;
        });
      } else {
        setState(() {
          _jadwalList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load schedules: $e';
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
        // Already on home page
        break;
      case 1:
        // Navigate to profile page
        AppRoutes.navigateAndReplace(context, AppRoutes.kurirProfile);
        break;
    }
  }

  Future<void> _updateJadwalStatus(JadwalModel jadwal, String newStatus) async {
    try {
      await _jadwalApi.updateJadwalStatus(jadwal.idJadwal, {
        'id_transaksi': jadwal.idTransaksi,
        'id_pegawai': jadwal.idPegawai,
        'tanggal': jadwal.tanggal,
        'status_jadwal': newStatus,
      });

      // Refresh the data
      if (_pegawaiProfile != null) {
        await _loadJadwalData(_pegawaiProfile!.idPegawai);
      }

      // Show success message
      String successMessage = '';
      if (newStatus == 'Selesai') {
        successMessage =
            'Pengiriman berhasil diselesaikan! Notifikasi telah dikirim ke pembeli dan penitip.';
      } else {
        successMessage = 'Status updated to $newStatus';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ReuseMart Kurir'),
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
          title: const Text('ReuseMart Kurir'),
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
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReuseMart Kurir'),
        backgroundColor: Colors.green.shade600,
        actions: [
          NotificationIcon(color: Colors.white, badgeColor: Colors.amber),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildWelcomeBanner(), _buildDeliveryScheduleSection()],
          ),
        ),
      ),
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
            _pegawaiProfile?.namaPegawai ?? 'Courier',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Job Title',
                  value: _pegawaiProfile?.jabatan?['nama_jabatan'] ?? 'Courier',
                  icon: Icons.work,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Deliveries',
                  value: '${_jadwalList.length}',
                  icon: Icons.local_shipping,
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

  Widget _buildDeliveryScheduleSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Schedules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _jadwalList.isEmpty
              ? _buildEmptyScheduleState()
              : Column(
                children:
                    _jadwalList
                        .map((jadwal) => _buildJadwalItem(jadwal))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No delivery schedules found',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalItem(JadwalModel jadwal) {
    // Define colors based on status
    Color statusColor;
    IconData statusIcon;

    switch (jadwal.statusJadwal) {
      case 'Menunggu Diambil':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Sedang Dikirim':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'Sudah Diambil':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Sudah Sampai':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case 'Selesai':
        statusColor = Colors.green.shade800;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    // Format date
    final formattedDate = _formatDate(jadwal.tanggal);

    return Card(
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
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${jadwal.idTransaksi}',
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    jadwal.statusJadwal,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Scheduled: $formattedDate',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (jadwal.transaksi != null && jadwal.transaksi!['alamat'] != null)
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
                      jadwal.transaksi!['alamat']['alamat_lengkap'] ??
                          'No address',
                      style: TextStyle(color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _buildStatusUpdateButtons(jadwal),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateButtons(JadwalModel jadwal) {
    // Only show buttons if the status can be updated
    if (jadwal.statusJadwal == 'Selesai') {
      return const SizedBox.shrink(); // No buttons for completed deliveries
    }

    // For pickup orders that are pending
    if (jadwal.statusJadwal == 'Menunggu Diambil') {
      return ElevatedButton.icon(
        onPressed: () => _updateJadwalStatus(jadwal, 'Sudah Diambil'),
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark as Picked Up'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    // For delivery orders in progress (with courier)
    if (jadwal.statusJadwal == 'Sedang di Kurir') {
      return ElevatedButton.icon(
        onPressed: () => _updateJadwalStatus(jadwal, 'Sudah Sampai'),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Mark as Arrived'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    // For delivery orders in progress
    if (jadwal.statusJadwal == 'Sedang Dikirim') {
      return ElevatedButton.icon(
        onPressed: () => _updateJadwalStatus(jadwal, 'Sudah Sampai'),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Mark as Arrived'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    // For orders that have been picked up or delivered but not yet marked as completed
    if (jadwal.statusJadwal == 'Sudah Diambil' ||
        jadwal.statusJadwal == 'Sudah Sampai') {
      return ElevatedButton.icon(
        onPressed: () => _updateJadwalStatus(jadwal, 'Selesai'),
        icon: const Icon(Icons.verified),
        label: const Text('Complete Delivery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    return const SizedBox.shrink(); // Default empty widget
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
