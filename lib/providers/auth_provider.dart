import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  int? _userId;
  String? _userType;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  bool get isAuth => _token != null;
  String? get token => _token;
  int? get userId => _userId;
  String? get userType => _userType;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['token'];
        _userId = responseData['user']['id_user'];
        _userType = responseData['user']['user_type'];
        _userData = responseData['user'];

        // Simpan data ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);
        prefs.setInt('userId', _userId!);
        prefs.setString('userType', _userType!);
        prefs.setString('userData', json.encode(_userData));

        // Register device token untuk notifikasi
        _registerDeviceToken();

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
        throw Exception(responseData['message'] ?? 'Login gagal');
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _userId = prefs.getInt('userId');
    _userType = prefs.getString('userType');

    if (prefs.containsKey('userData')) {
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        _userData = json.decode(userDataString);
      }
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userType = null;
    _userData = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    notifyListeners();
  }

  // Register device token for FCM notifications
  Future<void> _registerDeviceToken() async {
    try {
      if (_token == null) return;

      // Import dan gunakan package firebase_messaging untuk mendapatkan token FCM
      // final FirebaseMessaging messaging = FirebaseMessaging.instance;
      // final fcmToken = await messaging.getToken();

      // Untuk keperluan contoh, kita gunakan token dummy
      const fcmToken = 'dummy_fcm_token';

      if (fcmToken != null) {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/device-tokens'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: json.encode({'token': fcmToken}),
        );

        if (response.statusCode == 200) {
          print('Device token registered successfully');
        } else {
          print('Failed to register device token: ${response.body}');
        }
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }
}
