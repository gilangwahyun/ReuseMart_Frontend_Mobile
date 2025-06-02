import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/local_storage.dart';
import '../api/api_service.dart';
import '../utils/notification_helper.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil token autentikasi
      final token = await LocalStorage.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print(
        'Mengambil notifikasi dengan token auth: ${token.substring(0, 15)}...',
      );

      // Ambil notifikasi dari API
      final response = await http.get(
        Uri.parse('${BASE_URL}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print(
        'Response body: ${response.body.substring(0, min(100, response.body.length))}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data['data']);
          });
          print('Berhasil memuat ${_notifications.length} notifikasi');
        } else {
          print('Format data tidak valid: ${data.keys}');
          setState(() {
            _notifications = [];
          });
        }
      } else {
        print('Gagal mendapatkan notifikasi: ${response.statusCode}');
        setState(() {
          _notifications = [];
        });
      }
    } catch (e) {
      print('Error saat memuat notifikasi: $e');
      setState(() {
        _notifications = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk memformat tanggal
  String _formatDate(String dateString) {
    try {
      // Parse tanggal dari ISO format
      DateTime date = DateTime.parse(dateString);

      // Konversi ke zona waktu WIB (UTC+7)
      final wibOffset = const Duration(hours: 7);
      date = date.toUtc().add(wibOffset);

      final now = DateTime.now();
      final nowWib = DateTime.now().toUtc().add(wibOffset);

      // Format berdasarkan kapan notifikasi dibuat
      if (date.year == nowWib.year &&
          date.month == nowWib.month &&
          date.day == nowWib.day) {
        return 'Hari ini ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
      } else if (date.year == nowWib.year &&
          date.month == nowWib.month &&
          date.day == nowWib.day - 1) {
        return 'Kemarin ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
      }
    } catch (e) {
      print('Error saat memformat tanggal: $e');
      return dateString;
    }
  }

  // Handle tap pada notifikasi
  void _onNotificationTap(Map<String, dynamic> notification) {
    try {
      // Periksa apakah notifikasi sudah dibaca
      final bool isRead = notification['is_read'] ?? false;

      // Tandai sebagai sudah dibaca hanya jika belum dibaca
      if (!isRead) {
        _markAsRead(notification['id']);
      }

      // Tampilkan dialog detail notifikasi
      _showNotificationDetailDialog(notification);
    } catch (e) {
      print('Error saat menangani notifikasi: $e');
    }
  }

  // Tandai notifikasi sebagai sudah dibaca
  Future<void> _markAsRead(int notificationId) async {
    try {
      // Ambil token autentikasi
      final token = await LocalStorage.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      // Update di server
      final response = await http.put(
        Uri.parse('${BASE_URL}/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update di state lokal
        setState(() {
          final index = _notifications.indexWhere(
            (notif) => notif['id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });

        // Update notifikasi counter
        await NotificationHelper.decrementUnreadCount();
      }
    } catch (e) {
      print('Error saat menandai notifikasi dibaca: $e');
    }
  }

  // Tandai semua notifikasi sebagai dibaca
  Future<void> _markAllAsRead() async {
    try {
      // Ambil token autentikasi
      final token = await LocalStorage.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      // Tandai semua sebagai dibaca di server
      final response = await http.put(
        Uri.parse('${BASE_URL}/api/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update di state lokal
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            _notifications[i]['is_read'] = true;
          }
        });

        // Reset notifikasi counter
        await NotificationHelper.resetUnreadCount();

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Semua notifikasi ditandai sebagai dibaca'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('Gagal menandai semua notifikasi dibaca: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat menandai semua notifikasi dibaca: $e');
    }
  }

  // Tampilkan dialog detail notifikasi
  void _showNotificationDetailDialog(Map<String, dynamic> notification) {
    // Ambil data dari notifikasi
    String title = notification['title'] ?? 'Notifikasi';
    String body = notification['body'] ?? '';
    String dateString = notification['created_at'] ?? '';
    String formattedDate = _formatDate(dateString);

    // Ambil data tambahan jika ada
    Map<String, dynamic> notifData = {};
    if (notification['data'] is String && notification['data'].isNotEmpty) {
      try {
        notifData = json.decode(notification['data']);
      } catch (e) {
        print('Error parsing notification data: $e');
      }
    } else if (notification['data'] is Map) {
      notifData = notification['data'];
    }

    // Tentukan icon berdasarkan tipe notifikasi
    IconData notifIcon = Icons.notifications;
    String notifType = '';

    if (notifData.containsKey('type')) {
      if (notifData['type'] == 'penitipan_reminder') {
        notifIcon = Icons.event_available;
        notifType = 'Pengingat Penitipan';
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(notifIcon, color: Colors.green.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notifType.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        notifType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(body),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: TextStyle(color: Colors.green.shade600),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'markAllRead') {
                _markAllAsRead();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'markAllRead',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          size: 20,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text('Tandai semua dibaca'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
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
              : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: Colors.green.shade200),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Colors.green.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final bool isRead = notification['is_read'] ?? false;

          // Menentukan icon berdasarkan tipe notifikasi
          IconData notifIcon = Icons.notifications;
          try {
            if (notification['data'] is String) {
              final data = json.decode(notification['data']);
              if (data['type'] == 'penitipan_reminder') {
                notifIcon = Icons.event_available;
              }
            }
          } catch (e) {
            // Default to notifications icon
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isRead ? 1 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:
                  isRead
                      ? BorderSide.none
                      : BorderSide(color: Colors.green.shade300, width: 1),
            ),
            color: isRead ? Colors.white : Colors.green.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor:
                    isRead ? Colors.green.shade100 : Colors.green.shade600,
                foregroundColor: isRead ? Colors.green.shade700 : Colors.white,
                child: Icon(notifIcon),
              ),
              title: Text(
                notification['title'] ?? 'Notifikasi',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: isRead ? Colors.black87 : Colors.green.shade800,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    notification['body'] ?? '',
                    style: TextStyle(
                      color: isRead ? Colors.black54 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(notification['created_at'] ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => _onNotificationTap(notification),
            ),
          );
        },
      ),
    );
  }
}
