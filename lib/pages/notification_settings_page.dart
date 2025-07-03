import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../routes/app_routes.dart';
import '../utils/local_storage.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  String _fcmToken = 'Memuat token...';
  bool _isLoading = false;
  bool _isSendingToken = false;
  String _message = '';
  bool _success = false;
  String _authToken = '';

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
    _loadAuthToken();
  }

  // Load token otentikasi dari localStorage
  Future<void> _loadAuthToken() async {
    try {
      // Ambil token dari local storage
      final token = await LocalStorage.getToken();

      if (token != null && token.isNotEmpty) {
        setState(() {
          _authToken = token;
        });
      } else {
        // Alternatif: coba ambil token dari objek user
        final user = await LocalStorage.getUser();
        if (user != null && user.token != null && user.token!.isNotEmpty) {
          setState(() {
            _authToken = user.token!;
          });
        } else {
          // Alternatif: coba ambil dari user map
          final userMap = await LocalStorage.getUserMap();
          if (userMap != null &&
              userMap['user'] != null &&
              userMap['user']['token'] != null) {
            final userToken = userMap['user']['token'];
            setState(() {
              _authToken = userToken;
            });
          }
        }
      }
    } catch (e) {
      print('Error saat loading auth token: $e');
    }
  }

  // Ambil FCM Token
  Future<void> _loadFcmToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await FirebaseService.getToken();
      setState(() {
        _fcmToken = token ?? 'Token tidak tersedia';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Kirim token ke server
  Future<void> _sendTokenToServer() async {
    if (_fcmToken == 'Memuat token...' || _fcmToken == 'Token tidak tersedia') {
      return;
    }

    if (_authToken.isEmpty) {
      setState(() {
        _success = false;
        _message =
            'Token autentikasi tidak tersedia. Silahkan login terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSendingToken = true;
      _message = '';
      _success = false;
    });

    try {
      bool result = await FirebaseService.sendTokenToServer(
        _fcmToken,
        _authToken,
      );

      setState(() {
        _success = result;
        _message =
            result
                ? 'Token berhasil dikirim ke server!'
                : 'Gagal mengirim token ke server.';
        _isSendingToken = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _success = false;
        _isSendingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Cloud Messaging Token',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fcmToken,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _fcmToken));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Token disalin ke clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Salin token',
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadFcmToken,
                    child: const Text('Refresh Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSendingToken ? null : _sendTokenToServer,
                    child:
                        _isSendingToken
                            ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Mengirim...'),
                              ],
                            )
                            : const Text('Kirim Token ke Server'),
                  ),
                ),
              ],
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _success ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message,
                        style: TextStyle(
                          color:
                              _success
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Informasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Token FCM digunakan server untuk mengirim notifikasi ke perangkat Anda. '
              'Token autentikasi diambil otomatis dari data login Anda. '
              'Jika Anda tidak menerima notifikasi, coba refresh token dan kirim ulang ke server.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
