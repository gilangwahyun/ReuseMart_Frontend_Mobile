import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/auth_api.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthApi _authApi = AuthApi();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final bool isLoggedIn = await _authApi.isLoggedIn();
    if (isLoggedIn) {
      if (mounted) {
        _navigateToCorrectDashboard();
      }
    }
  }

  Future<void> _navigateToCorrectDashboard() async {
    final userData = await _authApi.getUserData();

    if (userData != null) {
      // Print the full user data to debug
      print("User data: $userData");

      final role = userData['role'];
      print("User role: $role");

      // Check for role strings that might correspond to courier
      if (role != null) {
        if (role.toString().toLowerCase().contains('kurir') ||
            role.toString().toLowerCase().contains('courier') ||
            role == 'Kurir') {
          print("Detected courier role: $role - navigating to courier home");
        }
      }

      if (mounted) {
        // Navigate based on role
        AppRoutes.navigateToMainFlow(context, true, role, userData);
      }
    } else {
      if (mounted) {
        print("No user data found, navigating to login page");
        AppRoutes.navigateToMainFlow(context, false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await _authApi.login({
          'email': _emailController.text,
          'password': _passwordController.text,
        });

        if (response != null && response['token'] != null) {
          // Print the login response for debugging
          print("Login response: $response");

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login berhasil!'),
              backgroundColor: Colors.green,
            ),
          );

          // Wait for success message to appear, then navigate to appropriate dashboard
          await Future.delayed(const Duration(seconds: 2));

          // Navigate to dashboard based on user role
          await _navigateToCorrectDashboard();
        } else {
          setState(() {
            _errorMessage = 'Login gagal, token tidak ditemukan.';
          });
        }
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () =>
                  AppRoutes.navigateAndClear(context, AppRoutes.informasiUmum),
        ),
        title: const Text(''), // Title kosong
      ),
      extendBodyBehindAppBar: true, // Agar AppBar transparan di atas gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nama Aplikasi
                  Text(
                    'ReuseMart',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Platform Daur Ulang Berbasis Konsinyasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 50),
                  // Card Login
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            CustomTextField(
                              label: 'Email',
                              hint: 'Masukkan email Anda',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@')) {
                                  return 'Masukkan email yang valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Masukkan password Anda',
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: _isLoading ? 'Memproses...' : 'Login',
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              backgroundColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
