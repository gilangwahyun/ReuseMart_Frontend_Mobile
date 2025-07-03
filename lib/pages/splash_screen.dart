import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../utils/local_storage.dart';
import '../api/auth_api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthApi _authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Tunggu 2 detik untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Cek apakah user sudah login secara ketat (validasi dengan API)
      final bool isLoggedIn = await _authApi.isLoggedIn();
      print("Status login (API validation): $isLoggedIn");

      // Jika sudah login, dapatkan role user
      String? userRole;
      if (isLoggedIn) {
        final user = await LocalStorage.getUser();
        userRole = user?.role;
        print("User role: $userRole");
      } else {
        // Jika token tidak valid, hapus semua data cache
        print("Token tidak valid, membersihkan cache...");
        await _authApi.clearAllCacheData();
      }

      if (!mounted) return;

      // Gunakan fungsi baru untuk navigasi berdasarkan status login dan role
      AppRoutes.navigateToMainFlow(context, isLoggedIn, userRole);
    } catch (e) {
      print("Error checking login: $e");
      // Jika terjadi error, hapus semua data cache untuk menghindari loop
      await _authApi.clearAllCacheData();

      if (!mounted) return;

      // Arahkan ke login page jika terjadi error
      AppRoutes.navigateToMainFlow(context, false, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade400, Colors.green.shade800],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau ikon app
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.recycling, size: 60, color: Colors.green),
              ),
            ),
            const SizedBox(height: 24),
            // Nama aplikasi
            const Text(
              'ReuseMart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Platform Konsinyasi Barang Bekas',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
