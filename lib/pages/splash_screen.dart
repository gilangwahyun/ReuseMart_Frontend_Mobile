import 'dart:async';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/local_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Tunggu 2 detik untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cek apakah user sudah login
    final bool isLoggedIn = await LocalStorage.isLoggedIn();

    if (!mounted) return;

    // Gunakan fungsi baru untuk navigasi berdasarkan status login
    AppRoutes.navigateToMainFlow(context, isLoggedIn);
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
