import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'routes/app_routes.dart';
import 'services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'utils/notification_helper.dart';

// Global navigator key untuk akses dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler teratas untuk FCM background message
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi sebelum menangani notifikasi background
  await Firebase.initializeApp();
  print("FCM background message diterima: ${message.messageId}");
  print("FCM background message data: ${message.data}");
}

Future<void> main() async {
  // Pastikan Flutter init selesai
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase sebelum menjalankan app
  await Firebase.initializeApp();

  // Set handler untuk background message di level teratas
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi service Firebase
  await FirebaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  // Setup untuk notifikasi push
  Future<void> _setupPushNotifications() async {
    try {
      // Cek dan minta izin notifikasi
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        criticalAlert: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Refresh jumlah notifikasi yang belum dibaca
      NotificationHelper.refreshUnreadCount();

      // Set handler foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.messageId}');
        print('Notification: ${message.notification?.title}');
        print('Data: ${message.data}');

        // Tampilkan notifikasi dari pesan yang diterima
        FirebaseService.showNotificationFromFcmMessage(message);

        // Refresh jumlah notifikasi yang belum dibaca
        NotificationHelper.refreshUnreadCount();
      });

      // Set handler ketika notifikasi ditekan saat app di background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          'Notification clicked when app in background: ${message.messageId}',
        );
        // Navigasi ke halaman yang sesuai berdasarkan data notifikasi
        _handleNotificationNavigation(message);
      });

      // Cek apakah aplikasi dibuka dari notifikasi saat tertutup
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state via notification');
        // Delay navigasi sampai widget tree sudah dibangun
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(initialMessage);
        });
      }

      // Subscribe ke topik umum
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (e) {
      print('Error setting up push notifications: $e');
    }
  }

  // Handle navigasi berdasarkan notifikasi
  void _handleNotificationNavigation(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'penitipan_reminder':
            Navigator.of(context).pushNamed(AppRoutes.penitipHome);
            break;

          // Tambahkan case lain jika diperlukan
          default:
            Navigator.of(context).pushNamed(AppRoutes.notifications);
        }
      }
    } catch (e) {
      print('Error handling notification navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReuseMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF42A5F5),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
    );
  }
}

// Observer untuk mendeteksi saat navigasi pertama kali selesai
class _FirstRunObserver extends NavigatorObserver {
  final VoidCallback onFirstRun;
  bool _firstBuild = true;

  _FirstRunObserver({required this.onFirstRun});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_firstBuild && previousRoute == null) {
      _firstBuild = false;
      onFirstRun();
    }
    super.didPush(route, previousRoute);
  }
}
