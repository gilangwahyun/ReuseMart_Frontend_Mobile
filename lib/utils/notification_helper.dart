import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'local_storage.dart';

class NotificationHelper {
  static const String _unreadCountKey = 'unread_notifications_count';
  static const String _lastFetchTimeKey = 'last_notification_fetch_time';

  // Cek apakah ada notifikasi yang belum dibaca
  static Future<bool> hasUnreadNotifications() async {
    try {
      final count = await getUnreadCount();
      return count > 0;
    } catch (e) {
      print('Error checking unread notifications: $e');
      return false;
    }
  }

  // Mendapatkan jumlah notifikasi yang belum dibaca
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek apakah perlu refresh data dari server
      final lastFetch = prefs.getInt(_lastFetchTimeKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Refresh data jika sudah lebih dari 5 menit atau belum pernah diambil
      if (currentTime - lastFetch > 5 * 60 * 1000 || lastFetch == 0) {
        await refreshUnreadCount();
      }

      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Refresh jumlah notifikasi yang belum dibaca dari server
  static Future<int> refreshUnreadCount() async {
    try {
      print('Refreshing unread notification count...');

      // Ambil token autentikasi
      final token = await LocalStorage.getToken();

      if (token == null || token.isEmpty) {
        print('Token not found, cannot refresh notifications');
        return 0;
      }

      // Ambil notifikasi dari API
      final response = await http.get(
        Uri.parse('${BASE_URL}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          final notifications = List<Map<String, dynamic>>.from(data['data']);

          // Hitung jumlah notifikasi yang belum dibaca
          final unreadCount =
              notifications
                  .where(
                    (notif) =>
                        notif['is_read'] == false || notif['is_read'] == 0,
                  )
                  .length;

          print('Found $unreadCount unread notifications');

          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_unreadCountKey, unreadCount);
          await prefs.setInt(
            _lastFetchTimeKey,
            DateTime.now().millisecondsSinceEpoch,
          );

          return unreadCount;
        } else {
          print('Invalid response format from API: ${data.keys}');
        }
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }

      return 0;
    } catch (e) {
      print('Error refreshing unread notifications count: $e');
      return 0;
    }
  }

  // Kurangi jumlah notifikasi yang belum dibaca (setelah dibaca)
  static Future<void> decrementUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_unreadCountKey) ?? 0;

      if (currentCount > 0) {
        await prefs.setInt(_unreadCountKey, currentCount - 1);
      }
    } catch (e) {
      print('Error decrementing unread count: $e');
    }
  }

  // Reset jumlah notifikasi yang belum dibaca (setelah mark all read)
  static Future<void> resetUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      print('Error resetting unread count: $e');
    }
  }
}
