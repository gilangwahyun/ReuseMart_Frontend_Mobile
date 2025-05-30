import 'package:flutter/material.dart';

// Import halaman-halaman
import '../pages/auth/login_page.dart';
import '../pages/client/home_page.dart';
import '../pages/client/pembeli_profile_page.dart';
import '../pages/client/penitip_profile_page.dart';
import '../pages/client/penitip_home_page.dart';
import '../pages/client/riwayat_transaksi_page.dart';
import '../pages/client/barang_penitip_page.dart';
import '../pages/info/informasi_umum_page.dart';
import '../pages/splash_screen.dart';

class AppRoutes {
  // Rute statis
  static const String splash = '/';
  static const String informasiUmum = '/informasi_umum';
  static const String login = '/login';
  static const String home = '/home';
  static const String pembeliProfile = '/pembeli_profile';
  static const String penitipProfile = '/penitip_profile';
  static const String riwayatTransaksi = '/riwayat_transaksi';

  // Rute untuk Penitip
  static const String penitipHome = '/penitip_home';
  static const String penitipBarang = '/penitip_barang';
  static const String riwayatPenitipan = '/riwayat_penitipan';
  static const String pendapatanPenitip = '/pendapatan_penitip';

  // Fungsi untuk mendapatkan semua rute
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      informasiUmum: (context) => const InformasiUmumPage(),
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      pembeliProfile: (context) => const PembeliProfilePage(),
      penitipProfile: (context) => const PenitipProfilePage(),
      riwayatTransaksi: (context) => const RiwayatTransaksiPage(),
      penitipHome: (context) => const PenitipHomePage(),
      penitipBarang: (context) => const BarangPenitipPage(),
      // Tambahkan rute lain di sini
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
