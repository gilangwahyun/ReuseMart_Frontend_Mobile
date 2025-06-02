import 'package:flutter/material.dart';

// Import halaman-halaman
import '../pages/auth/login_page.dart';
import '../pages/client/home_page.dart';
import '../pages/client/pembeli_profile_page.dart';
import '../pages/client/penitip_profile_page.dart';
import '../pages/client/penitip_home_page.dart';
import '../pages/client/barang_penitip_page.dart';
import '../pages/info/informasi_umum_page.dart';
import '../pages/splash_screen.dart';
import '../pages/notification_settings_page.dart';
import '../pages/notification_list_page.dart';
import '../pages/settings_page.dart';

class AppRoutes {
  // Rute statis
  static const String splash = '/';
  static const String informasiUmum = '/informasi_umum';
  static const String login = '/login';
  static const String home = '/home';
  static const String pembeliProfile = '/pembeli_profile';
  static const String penitipProfile = '/penitip_profile';
  static const String notificationSettings = '/notification_settings';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // Rute untuk Penitip
  static const String penitipHome = '/penitip/home';
  static const String penitipCreateBarang = '/penitip/create-barang';
  static const String penitipBarang = '/penitip/barang';

  // Fungsi untuk mendapatkan semua rute
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      informasiUmum: (context) => const InformasiUmumPage(),
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      pembeliProfile: (context) => const PembeliProfilePage(),
      penitipProfile: (context) => const PenitipProfilePage(),
      penitipHome: (context) => const PenitipHomePage(),
      penitipCreateBarang:
          (context) => const Scaffold(
            body: Center(child: Text('Halaman Create Barang')),
          ),
      penitipBarang: (context) => const BarangPenitipPage(),
      notificationSettings: (context) => const NotificationSettingsPage(),
      notifications: (context) => const NotificationListPage(),
      settings: (context) => const SettingsPage(),
    };
  }

  // Fungsi untuk navigasi dengan nama rute
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  // Fungsi untuk navigasi dan mengganti halaman saat ini (replace)
  static Future<dynamic> navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // Fungsi untuk navigasi dan menghapus semua rute sebelumnya
  static Future<dynamic> navigateAndClear(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  // Fungsi untuk navigasi ke alur utama berdasarkan status login dan role
  static void navigateToMainFlow(
    BuildContext context,
    bool isLoggedIn, [
    String? role,
  ]) {
    if (isLoggedIn) {
      // Jika sudah login, navigasi berdasarkan role
      if (role == 'Penitip') {
        navigateAndClear(context, penitipHome);
      } else {
        // Default untuk role Pembeli atau lainnya
        navigateAndClear(context, home);
      }
    } else {
      // Jika belum login, navigasi ke informasi umum
      navigateAndClear(context, informasiUmum);
    }
  }
}
