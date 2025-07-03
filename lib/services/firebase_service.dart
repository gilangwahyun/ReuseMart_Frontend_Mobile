import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/local_storage.dart';
import '../api/api_service.dart'; // Import untuk menggunakan BASE_URL
import 'package:flutter/material.dart';
import 'dart:typed_data';

// Top-level function untuk background message handler (wajib ada)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    'Pesan background diterima: ${message.messageId} - ${message.notification?.title ?? "No title"}',
  );

  // Tambahkan log untuk memahami pesan yang diterima
  print('Background message data: ${message.data}');
  print(
    'Background message notification: ${message.notification?.title}, ${message.notification?.body}',
  );
}

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Channel ID untuk Android
  static const String CHANNEL_ID = "high_importance_channel";
  static const String CHANNEL_NAME = "High Importance Notifications";
  static const String CHANNEL_DESC =
      "Channel untuk notifikasi penting dari ReuseMart";

  // Base URL API
  static final String _baseUrl = '$BASE_URL/api';

  // Key untuk token FCM
  static const String _tokenKey = 'fcm_token';

  // Inisialisasi Firebase
  static Future<void> initialize() async {
    try {
      // Inisialisasi Firebase
      await Firebase.initializeApp();
      print("Firebase berhasil diinisialisasi");

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permission untuk notifikasi
      await _requestPermission();

      // Setup notification channels
      await _setupNotificationChannel();

      // Setup handlers untuk berbagai state notifikasi
      _setupNotificationHandlers();

      // Refresh dan simpan token
      await refreshAndSaveToken();

      // Kirim token ke server jika user sudah login
      await sendTokenAfterLogin();

      print("Inisialisasi Firebase Service lengkap");
    } catch (e) {
      print("Error saat inisialisasi Firebase Service: $e");
    }
  }

  // Minta izin untuk menampilkan notifikasi
  static Future<bool> _requestPermission() async {
    try {
      // Minta izin ke sistem
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        carPlay: true,
        criticalAlert: true,
        provisional: false,
      );

      // Log status izin
      print('Status izin notifikasi: ${settings.authorizationStatus}');

      // Izinkan tampilan notifikasi foreground di iOS
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error saat meminta izin notifikasi: $e');
      return false;
    }
  }

  // Setup channel notifikasi
  static Future<void> _setupNotificationChannel() async {
    // Channel untuk Android (umum)
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      CHANNEL_ID,
      CHANNEL_NAME,
      description: CHANNEL_DESC,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      ledColor: Colors.blue,
    );

    // Buat channel di sistem Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Channel tambahan untuk notifikasi penitipan
    final AndroidNotificationChannel penitipanChannel =
        AndroidNotificationChannel(
          'penitipan_reminders',
          'Pengingat Penitipan',
          description: 'Notifikasi untuk pengingat batas waktu penitipan',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

    // Buat channel penitipan di sistem Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(penitipanChannel);

    // Inisialisasi settings untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Inisialisasi settings untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Inisialisasi settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Inisialisasi plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notifikasi ditekan: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            print('Error parsing payload: $e');
          }
        }
      },
    );

    print('Notification channels setup completed successfully!');
  }

  // Setup handlers untuk notifikasi
  static void _setupNotificationHandlers() {
    try {
      // Handler untuk notifikasi saat app di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
          'Notifikasi diterima (foreground): ${message.notification?.title}',
        );
        print('Data: ${message.data}');

        // Langsung tampilkan notifikasi local dari data FCM
        showNotificationFromFcmMessage(message);
      });

      // Handler untuk notifikasi saat app di background tapi terbuka
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          'Aplikasi dibuka dari notifikasi (background): ${message.notification?.title}',
        );
        _handleNotificationTap(message.data);
      });

      // Tambahkan listener untuk background message (jika tidak berhasil ditangani oleh top-level handler)
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Cek notifikasi pendorong awal (jika aplikasi dibuka dari notifikasi saat terminated)
      FirebaseMessaging.instance.getInitialMessage().then((
        RemoteMessage? message,
      ) {
        if (message != null) {
          print(
            'Aplikasi dibuka dari notifikasi awal (terminated): ${message.notification?.title}',
          );
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationTap(message.data);
          });
        }
      });

      // Debug status FCM
      checkAndLogFcmStatus();
    } catch (e) {
      print('Error dalam setup notification handlers: $e');
    }
  }

  // Fungsi untuk menampilkan notifikasi lokal
  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = CHANNEL_ID,
  }) async {
    try {
      print('Menampilkan notifikasi lokal: $title - $body');
      print('Channel ID: $channelId');
      print('Payload: $payload');

      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == CHANNEL_ID ? CHANNEL_NAME : 'Pengingat Penitipan',
            channelDescription:
                channelId == CHANNEL_ID
                    ? CHANNEL_DESC
                    : 'Notifikasi untuk pengingat batas waktu penitipan',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ReuseMart Notification',
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            sound: const RawResourceAndroidNotificationSound(
              'notification_sound',
            ),
            enableLights: true,
            playSound: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: payload,
      );

      print('Notifikasi lokal berhasil ditampilkan');
    } catch (e) {
      print('Error saat menampilkan notifikasi: $e');
    }
  }

  // Coba tampilkan notifikasi dari data message FCM
  static Future<void> showNotificationFromFcmMessage(
    RemoteMessage message,
  ) async {
    try {
      print('Mencoba menampilkan notifikasi dari FCM message');

      final notification = message.notification;
      final data = message.data;

      // Log data notifikasi
      print('Notification: ${notification?.title} - ${notification?.body}');
      print('Data: $data');

      // Prioritaskan nilai dari notification, kemudian data
      final title = notification?.title ?? data['title'] ?? 'Notifikasi Baru';
      final body =
          notification?.body ?? data['body'] ?? 'Anda memiliki notifikasi baru';

      // Tentukan channel ID
      final channelId = data['channel_id'] ?? CHANNEL_ID;

      // Tentukan ID notifikasi yang unique untuk memastikan tidak di-overwrite
      int notificationId;
      if (data.containsKey('notification_id')) {
        notificationId =
            int.tryParse(data['notification_id'].toString()) ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000);
      } else {
        notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
          100000,
        );
      }

      await _showLocalNotification(
        id: notificationId,
        title: title,
        body: body,
        payload: json.encode(data),
        channelId: channelId,
      );
    } catch (e) {
      print('Error menampilkan notifikasi dari FCM: $e');
    }
  }

  // Debug status FCM dan informasi perangkat
  static Future<void> checkAndLogFcmStatus() async {
    try {
      final notificationSettings = await _messaging.getNotificationSettings();
      final token = await _messaging.getToken();
      final apnsToken = await _messaging.getAPNSToken();

      print('==== FCM STATUS ====');
      print(
        'Authorization status: ${notificationSettings.authorizationStatus}',
      );
      print('FCM Token available: ${token != null}');
      print('FCM Token length: ${token?.length ?? 0}');
      print(
        'FCM Token preview: ${token != null ? token.substring(0, min(20, token.length)) : "null"}...',
      );
      print('APNS Token: $apnsToken');
      print('===================');
    } catch (e) {
      print('Error checking FCM status: $e');
    }
  }

  // Handle tap pada notifikasi
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('Menangani tap notifikasi dengan data: $data');

    if (data.containsKey('type')) {
      final notificationType = data['type'];

      if (notificationType == 'penitipan_reminder') {
        print(
          'Navigasi ke detail penitipan dengan ID: ${data['penitipan_id']}',
        );
        _saveLastNotificationData(data);
      }
    }
  }

  // Simpan data notifikasi terakhir
  static Future<void> _saveLastNotificationData(
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_data', json.encode(data));
  }

  // Ambil data notifikasi terakhir
  static Future<Map<String, dynamic>?> getLastNotificationData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('last_notification_data');
    if (dataString != null && dataString.isNotEmpty) {
      return json.decode(dataString);
    }
    return null;
  }

  // Bersihkan data notifikasi terakhir
  static Future<void> clearLastNotificationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_data');
  }

  // Ambil dan simpan token FCM
  static Future<String?> refreshAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        print('FCM Token: ${token.substring(0, 20)}...');
        return token;
      }
      return null;
    } catch (e) {
      print('Error mendapatkan FCM token: $e');
      return null;
    }
  }

  // Ambil token dari storage
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString(_tokenKey);

      if (token == null) {
        token = await refreshAndSaveToken();
      }

      return token;
    } catch (e) {
      print('Error mengambil FCM token: $e');
      return null;
    }
  }

  // Kirim token ke server backend
  static Future<bool> sendTokenToServer(String token, String authToken) async {
    try {
      print('Mengirim FCM token ke server...');
      print('Token FCM: ${token.substring(0, min(20, token.length))}...');
      print(
        'Token Auth: ${authToken.substring(0, min(15, authToken.length))}...',
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/device-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token, 'device_type': 'android'}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token berhasil dikirim ke server');
        // Simpan token ke shared preferences sebagai indikator bahwa token telah berhasil dikirim
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('token_sent_to_server', true);
        return true;
      } else {
        print(
          'Gagal mengirim token: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error saat mengirim token: $e');
      return false;
    }
  }

  // Listener untuk perubahan token
  static void setupTokenRefreshListener(String authToken) {
    _messaging.onTokenRefresh.listen((String newToken) {
      print('Token FCM diperbarui: ${newToken.substring(0, 20)}...');

      // Simpan token baru
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_tokenKey, newToken);
      });

      // Kirim ke server
      sendTokenToServer(newToken, authToken);
    });
  }

  // Cek dan kirim token setelah login
  static Future<void> sendTokenAfterLogin() async {
    try {
      // Cek jika user sudah login
      final authToken = await LocalStorage.getToken();
      if (authToken == null || authToken.isEmpty) {
        print('User belum login, tidak mengirim token ke server');
        return;
      }

      // Ambil token FCM
      final fcmToken = await getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token tidak tersedia');
        // Coba refresh token jika tidak tersedia
        await refreshAndSaveToken();
        return;
      }

      // Kirim token ke server
      print('User sudah login, mengirim FCM token ke server');
      final result = await sendTokenToServer(fcmToken, authToken);

      if (result) {
        print('FCM token berhasil dikirim ke server');
        // Setup listener perubahan token
        setupTokenRefreshListener(authToken);
      } else {
        print(
          'Gagal mengirim FCM token ke server. Akan mencoba kembali saat berikutnya.',
        );
      }
    } catch (e) {
      print('Error saat pengiriman token setelah login: $e');
    }
  }

  // Test mengirim notifikasi lokal
  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      id: DateTime.now().millisecond,
      title: 'Notifikasi Test',
      body: 'Ini adalah notifikasi test dari ReuseMart',
      payload: json.encode({'type': 'test', 'time': DateTime.now().toString()}),
    );
  }

  // Untuk kompatibilitas dengan kode lama
  static Future<bool> testSendNotification(
    String authToken,
    String title,
    String body,
  ) async {
    try {
      await _showLocalNotification(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        payload: json.encode({
          'type': 'test',
          'time': DateTime.now().toString(),
        }),
      );
      return true;
    } catch (e) {
      print('Error saat menampilkan notifikasi: $e');
      return false;
    }
  }

  // Mendapatkan diagnostik status FCM untuk debugging
  static Future<Map<String, dynamic>> getFcmDiagnostics() async {
    try {
      final fcmToken = await getToken();
      final prefs = await SharedPreferences.getInstance();
      final tokenSentToServer = prefs.getBool('token_sent_to_server') ?? false;

      // Coba cek izin notifikasi
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();

      return {
        'fcm_token': fcmToken ?? 'Tidak tersedia',
        'token_sent_to_server': tokenSentToServer,
        'notification_permission': settings.authorizationStatus.toString(),
        'firebase_initialized': Firebase.apps.isNotEmpty,
        'channel_initialized': true,
        'devices_count': 1,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'fcm_token': await getToken() ?? 'Tidak tersedia',
      };
    }
  }

  // Mendapatkan token autentikasi untuk operasi notifikasi
  static Future<String?> getAuthTokenForNotification() async {
    try {
      // Coba ambil token dari LocalStorage
      final authToken = await LocalStorage.getToken();
      if (authToken != null && authToken.isNotEmpty) {
        return authToken;
      }

      // Jika tidak ada, coba ambil dari user object
      final user = await LocalStorage.getUser();
      if (user != null && user.token != null && user.token!.isNotEmpty) {
        return user.token;
      }

      // Jika masih tidak ada, coba ambil dari userMap
      final userMap = await LocalStorage.getUserMap();
      if (userMap != null) {
        // Cek apakah token ada di level pertama
        if (userMap['token'] != null && userMap['token'] is String) {
          return userMap['token'];
        }

        // Cek apakah token ada di dalam objek user
        if (userMap['user'] != null && userMap['user'] is Map) {
          final nestedUser = userMap['user'] as Map;
          if (nestedUser['token'] != null && nestedUser['token'] is String) {
            return nestedUser['token'];
          }
        }
      }

      return null;
    } catch (e) {
      print('Error mendapatkan auth token: $e');
      return null;
    }
  }
}
