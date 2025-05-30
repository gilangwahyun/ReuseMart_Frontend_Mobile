import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';

class LocalStorage {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _profileKey = 'profile';
  static const String _penitipIdKey = 'id_penitip';
  static const String _pembeliIdKey = 'id_pembeli';

  // Menyimpan string data dengan key tertentu
  static Future<bool> saveData(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  // Mendapatkan string data dengan key tertentu
  static Future<String?> getData(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Menghapus data dengan key tertentu
  static Future<bool> removeData(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // Menyimpan token
  static Future<bool> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  // Mendapatkan token
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Menyimpan data user
  static Future<bool> saveUser(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Mendapatkan data user
  static Future<UserModel?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(_userKey);

    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }

    return null;
  }

  // Menyimpan data profil lengkap
  static Future<bool> saveProfile(UserProfileModel profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // Mendapatkan data profil lengkap
  static Future<UserProfileModel?> getProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? profileData = prefs.getString(_profileKey);

    if (profileData != null) {
      return UserProfileModel.fromJson(jsonDecode(profileData));
    }

    return null;
  }

  // Menyimpan token dan user data
  static Future<bool> saveAuthData(UserModel user) async {
    bool tokenSaved = await saveToken(user.token ?? '');
    bool userSaved = await saveUser(user);
    return tokenSaved && userSaved;
  }

  // Menyimpan data user dalam bentuk Map
  static Future<bool> saveUserMap(Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userKey, jsonEncode(userData));
  }

  // Mendapatkan data user dalam bentuk Map
  static Future<Map<String, dynamic>?> getUserMap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(_userKey);

    if (userData != null) {
      return jsonDecode(userData);
    }

    return null;
  }

  // Menghapus data autentikasi
  static Future<bool> clearAuthData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_profileKey);
    return true;
  }

  // Menghapus semua data tersimpan
  static Future<bool> clearAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  // Mengecek apakah sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Mengecek apakah ada data profil
  static Future<bool> hasProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? profileData = prefs.getString(_profileKey);
    return profileData != null && profileData.isNotEmpty;
  }

  // Menyimpan id penitip
  static Future<bool> savePenitipId(String idPenitip) async {
    return saveData(_penitipIdKey, idPenitip);
  }

  // Mendapatkan id penitip
  static Future<int?> getPenitipId() async {
    final idPenitip = await getData(_penitipIdKey);
    if (idPenitip != null && idPenitip.isNotEmpty) {
      try {
        return int.parse(idPenitip);
      } catch (e) {
        print("Error parsing id_penitip: $e");
        return null;
      }
    }
    return null;
  }
}
