import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/local_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '1.0.0';
  String _appName = 'ReuseMart';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading app info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari akun ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('KELUAR'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      await LocalStorage.clearUserData();
      AppRoutes.navigateAndClear(context, AppRoutes.login);
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AboutDialog(
            applicationName: _appName,
            applicationVersion: 'Versi $_appVersion (Build $_buildNumber)',
            applicationIcon: Image.asset(
              'assets/images/logo.png',
              width: 50,
              height: 50,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.eco, size: 50, color: Colors.green.shade600),
            ),
            children: [
              const SizedBox(height: 16),
              const Text(
                'ReuseMart adalah platform konsinyasi barang bekas yang membantu masyarakat untuk menjual barang bekas dengan mudah dan aman.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2024 ReuseMart. Semua hak dilindungi undang-undang.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
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
              : ListView(
                children: [
                  // About Section
                  _buildSectionHeader('Tentang & Bantuan'),

                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.green.shade600,
                    ),
                    title: const Text('Tentang ReuseMart'),
                    subtitle: Text('Versi $_appVersion'),
                    onTap: _showAboutDialog,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: Colors.green.shade600,
                    ),
                    title: const Text('Bantuan & Dukungan'),
                    subtitle: const Text(
                      'Dapatkan bantuan penggunaan aplikasi',
                    ),
                    onTap: () {
                      // Navigate to help page or show help dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur bantuan akan segera tersedia'),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 32),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Keluar dari Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }
}
