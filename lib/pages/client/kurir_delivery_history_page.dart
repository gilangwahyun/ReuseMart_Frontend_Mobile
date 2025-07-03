import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../api/jadwal_api.dart';
import '../../api/pegawai_api.dart';
import '../../models/jadwal_model.dart';
import '../../models/pegawai_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/notification_icon.dart';

class KurirDeliveryHistoryPage extends StatefulWidget {
  const KurirDeliveryHistoryPage({super.key});

  @override
  State<KurirDeliveryHistoryPage> createState() =>
      _KurirDeliveryHistoryPageState();
}

class _KurirDeliveryHistoryPageState extends State<KurirDeliveryHistoryPage> {
  final AuthApi _authApi = AuthApi();
  final PegawaiApi _pegawaiApi = PegawaiApi();
  final JadwalApi _jadwalApi = JadwalApi();

  PegawaiModel? _pegawaiProfile;
  List<JadwalModel> _completedDeliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveryHistory();
  }

  Future<void> _loadDeliveryHistory() async {
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
      });

      // Load completed deliveries for this courier
      await _loadCompletedDeliveries(pegawai.idPegawai);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load delivery history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompletedDeliveries(int pegawaiId) async {
    try {
      final jadwalData = await _jadwalApi.getJadwalByPegawai(pegawaiId);

      if (jadwalData is List) {
        // Filter only completed deliveries (Sudah Sampai, Sudah Diambil, or Selesai)
        final completedJadwals =
            jadwalData
                .map((item) => JadwalModel.fromJson(item))
                .where(
                  (jadwal) =>
                      jadwal.statusJadwal == 'Sudah Sampai' ||
                      jadwal.statusJadwal == 'Sudah Diambil' ||
                      jadwal.statusJadwal == 'Selesai',
                )
                .toList();

        // Sort by date (most recent first)
        completedJadwals.sort(
          (a, b) =>
              DateTime.parse(b.tanggal).compareTo(DateTime.parse(a.tanggal)),
        );

        setState(() {
          _completedDeliveries = completedJadwals;
          _isLoading = false;
        });
      } else {
        setState(() {
          _completedDeliveries = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load completed deliveries: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery History'),
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
          title: const Text('Delivery History'),
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
                onPressed: () => _loadDeliveryHistory(),
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
        title: const Text('Delivery History'),
        backgroundColor: Colors.green.shade600,
        actions: [
          NotificationIcon(color: Colors.white, badgeColor: Colors.amber),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeliveryHistory,
        child:
            _completedDeliveries.isEmpty
                ? _buildEmptyHistoryState()
                : _buildDeliveryHistoryList(),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No completed deliveries yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed deliveries will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedDeliveries.length,
      itemBuilder: (context, index) {
        final jadwal = _completedDeliveries[index];
        return _buildDeliveryHistoryItem(jadwal);
      },
    );
  }

  Widget _buildDeliveryHistoryItem(JadwalModel jadwal) {
    // Format date
    final formattedDate = _formatDate(jadwal.tanggal);

    // Define status properties
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (jadwal.statusJadwal == 'Selesai') {
      statusIcon = Icons.verified;
      statusColor = Colors.green.shade800;
      statusText = 'Completed';
    } else {
      final isPickup = jadwal.statusJadwal == 'Sudah Diambil';
      statusIcon = isPickup ? Icons.inventory_2 : Icons.local_shipping;
      statusColor = Colors.green.shade700;
      statusText = isPickup ? 'Picked Up' : 'Delivered';
    }

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${jadwal.idTransaksi}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $formattedDate',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        jadwal.statusJadwal == 'Selesai'
                            ? Colors.green.shade100
                            : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (jadwal.transaksi != null && jadwal.transaksi!['alamat'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jadwal.transaksi!['alamat']['alamat_lengkap'] ??
                          'No address',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
