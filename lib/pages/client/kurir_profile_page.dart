import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/pegawai_api.dart';
import '../../models/pegawai_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/notification_icon.dart';

class KurirProfilePage extends StatefulWidget {
  const KurirProfilePage({super.key});

  @override
  State<KurirProfilePage> createState() => _KurirProfilePageState();
}

class _KurirProfilePageState extends State<KurirProfilePage> {
  final AuthApi _authApi = AuthApi();
  final PegawaiApi _pegawaiApi = PegawaiApi();

  PegawaiModel? _pegawaiProfile;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 1; // 1 for profile

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

      // Get user data
      final userData = await _authApi.getUserData();
      if (userData == null) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final userId = userData['id_user'];

      // Get pegawai data by user ID
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout Confirmation'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
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
  }

  void _navigateToDeliveryHistory() {
    Navigator.pushNamed(context, AppRoutes.kurirDeliveryHistory);
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
              onPressed: () => _loadProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green.shade600,
        actions: [
          NotificationIcon(color: Colors.white, badgeColor: Colors.amber),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildProfileDetails(),
            _buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavBarTapped,
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _buildProfileHeader(),
//           _buildProfileDetails(),
//           _buildLogoutButton(),
//         ],
//       ),
//     );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
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
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.person, size: 60, color: Colors.green.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            _pegawaiProfile?.namaPegawai ?? 'Courier',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _pegawaiProfile?.jabatan?['nama_jabatan'] ?? 'Courier',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.call,
            title: 'Phone Number',
            value: _pegawaiProfile?.noTelepon ?? '-',
          ),
          _buildInfoItem(
            icon: Icons.cake,
            title: 'Date of Birth',
            value: _formatDate(_pegawaiProfile?.tanggalLahir ?? ''),
          ),
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Address',
            value: _pegawaiProfile?.alamat ?? '-',
          ),
          if (_pegawaiProfile?.user != null)
            _buildInfoItem(
              icon: Icons.email,
              title: 'Email',
              value: _pegawaiProfile?.user?['email'] ?? '-',
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Delivery History Button
          ElevatedButton.icon(
            onPressed: _navigateToDeliveryHistory,
            icon: const Icon(Icons.history),
            label: const Text('Delivery History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
          const SizedBox(height: 16),
          // Logout Button
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
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

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '-';

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
