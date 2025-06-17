import 'package:flutter/material.dart';
import '../api/pegawai_api.dart';
import '../models/pegawai_model.dart';

// Import halaman-halaman
import '../pages/auth/login_page.dart';
import '../pages/client/home_page.dart';
import '../pages/client/barang_detail_page.dart';
import '../pages/client/barang_detail_pembeli_page.dart';
import '../pages/client/pembeli_profile_page.dart';
import '../pages/client/penitip_profile_page.dart';
import '../pages/client/penitip_home_page.dart';
import '../pages/client/penitip_container_page.dart';
import '../pages/client/pembeli_container_page.dart';
import '../pages/client/barang_penitip_page.dart';
import '../pages/client/kurir_home_page.dart';
import '../pages/client/kurir_profile_page.dart';
import '../pages/client/kurir_container_page.dart';
import '../pages/client/hunter_profile_page.dart';
import '../pages/client/hunter_home_page.dart';
import '../pages/client/hunter_container_page.dart';
import '../pages/client/merchandise_page.dart';
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
  static const String detailBarang = '/barang/detail';
  static const String pembeliProfile = '/pembeli_profile';
  static const String penitipProfile = '/penitip/profile';
  static const String notificationSettings = '/notification_settings';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String merchandise = '/merchandise';
  static const String detailBarangPembeli = '/detail-barang-pembeli';

  // Rute untuk Pembeli
  static const String pembeliContainer = '/pembeli/container';

  // Rute untuk Penitip
  static const String penitipHome = '/penitip/home';
  static const String penitipCreateBarang = '/penitip/create-barang';
  static const String penitipBarang = '/penitip/barang';
  static const String penitipContainer = '/penitip/container';

  // Rute untuk Kurir
  static const String kurirHome = '/kurir/home';
  static const String kurirProfile = '/kurir/profile';
  static const String kurirContainer = '/kurir/container';

  // Rute untuk Hunter
  static const String hunterProfile = '/hunter/profile';
  static const String hunterHome = '/hunter/home';
  static const String hunterContainer = '/hunter/container';

  // Fungsi untuk mendapatkan semua rute
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      informasiUmum: (context) => const InformasiUmumPage(),
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(isEmbedded: false),
      pembeliContainer: (context) => const PembeliContainerPage(),
      detailBarang: (context) {
        print("DEBUG: Detail barang route triggered");
        final args = ModalRoute.of(context)!.settings.arguments;
        print("DEBUG: Route arguments: $args");
        if (args == null) {
          print("DEBUG ERROR: No arguments provided to detailBarang route");
          return const Scaffold(
            body: Center(child: Text('Error: Tidak ada ID barang')),
          );
        }

        try {
          final Map<String, dynamic> mapArgs = args as Map<String, dynamic>;
          final idBarang = mapArgs['id_barang'];
          print("DEBUG: Showing detail for barang ID: $idBarang");
          return BarangDetailPage(idBarang: idBarang);
        } catch (e) {
          print("DEBUG ERROR: Invalid arguments format: $e");
          return Scaffold(
            body: Center(child: Text('Error: Format argumen tidak valid: $e')),
          );
        }
      },
      pembeliProfile: (context) => const PembeliProfilePage(isEmbedded: false),
      penitipProfile: (context) => const PenitipProfilePage(isEmbedded: false),
      penitipHome: (context) => const PenitipHomePage(isEmbedded: false),
      penitipContainer: (context) => const PenitipContainerPage(),
      penitipCreateBarang:
          (context) => const Scaffold(
            body: Center(child: Text('Halaman Create Barang')),
          ),
      penitipBarang: (context) => const BarangPenitipPage(),
      kurirHome: (context) => const KurirHomePage(),
      kurirProfile: (context) => const KurirProfilePage(),
      kurirContainer: (context) => const KurirContainerPage(),
      hunterProfile: (context) => const HunterProfilePage(),
      hunterHome: (context) => const HunterHomePage(),
      hunterContainer: (context) => const HunterContainerPage(),
      notificationSettings: (context) => const NotificationSettingsPage(),
      notifications: (context) => const NotificationListPage(),
      settings: (context) => const SettingsPage(),
      merchandise: (context) => const MerchandisePage(),
      detailBarangPembeli: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Tidak ada ID barang')),
          );
        }

        try {
          final Map<String, dynamic> mapArgs = args as Map<String, dynamic>;
          final int idBarang = mapArgs['id_barang'] as int? ?? 0;
          return BarangDetailPembeliPage(idBarang: idBarang);
        } catch (e) {
          return Scaffold(
            body: Center(child: Text('Error: Format argumen tidak valid: $e')),
          );
        }
      },
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
    Map<String, dynamic>? userData,
  ]) async {
    if (isLoggedIn) {
      // Print debug info
      print("Navigating based on role: '$role'");

      // Convert role to lowercase for case-insensitive comparison
      final roleLower = role?.toLowerCase() ?? '';

      // Jika sudah login, navigasi berdasarkan role
      if (role == 'Penitip') {
        print("Navigating to penitip container");
        navigateAndClear(context, penitipContainer);
      } else if (roleLower == 'kurir' || roleLower.contains('kurir')) {
        print("Navigating to courier container");
        navigateAndClear(context, kurirContainer);
      } else if (roleLower == 'hunter' || roleLower.contains('hunter')) {
        print("Navigating to hunter container");
        navigateAndClear(context, hunterContainer);
      } else if (role == 'Pegawai') {
        // For employees, check jabatan ID to determine the specific role
        print("Role is Pegawai, checking jabatan...");

        // Get user ID from userData
        final userId = userData?['id_user'];
        if (userId != null) {
          try {
            // Fetch pegawai data by user ID
            final pegawaiApi = PegawaiApi();
            final pegawaiData = await pegawaiApi.getPegawaiByUserId(userId);

            if (pegawaiData != null) {
              final pegawai = PegawaiModel.fromJson(pegawaiData);
              final idJabatan = pegawai.idJabatan;

              print("Pegawai found with jabatan ID: $idJabatan");

              // Navigate based on jabatan ID
              if (idJabatan == 5) {
                // Hunter (ID 5)
                print("Pegawai is a Hunter, navigating to hunter container");
                navigateAndClear(context, hunterContainer);
                return;
              } else if (idJabatan == 6) {
                // Kurir/Courier (ID 6)
                print("Pegawai is a Courier, navigating to courier container");
                navigateAndClear(context, kurirContainer);
                return;
              }
            }
          } catch (e) {
            print("Error checking pegawai role: $e");
            // Fallback to default page if error occurs
          }
        }

        // Default fallback for Pegawai if jabatan can't be determined
        print(
          "Could not determine specific pegawai role, navigating to default home",
        );
        navigateAndClear(context, home);
      } else {
        // Default untuk role Pembeli atau lainnya
        print("Navigating to pembeli container");
        navigateAndClear(context, pembeliContainer);
      }
    } else {
      // Jika belum login, navigasi ke informasi umum
      print("Not logged in, navigating to general info");
      navigateAndClear(context, informasiUmum);
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case detailBarang:
        final args = settings.arguments as Map<String, dynamic>?;
        final idBarang = args?['id_barang'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (context) => BarangDetailPage(idBarang: idBarang),
        );

      case detailBarangPembeli:
        final args = settings.arguments as Map<String, dynamic>?;
        final idBarang = args?['id_barang'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (context) => BarangDetailPembeliPage(idBarang: idBarang),
        );

      default:
        // Return a fallback route instead of null
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: Text('Route tidak ditemukan: ${settings.name}'),
                ),
              ),
        );
    }
  }
}
