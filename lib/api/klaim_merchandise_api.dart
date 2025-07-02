import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/klaim_merchandise_model.dart';
import 'api_service.dart';
import 'dart:developer' as developer;
import '../utils/local_storage.dart';

class KlaimMerchandiseApi {
  final ApiService _apiService = ApiService();

  // Get klaim merchandise by pembeli ID
  Future<List<KlaimMerchandise>> getByPembeli(int idPembeli) async {
    try {
      developer.log('Fetching klaim merchandise for pembeli ID: $idPembeli');
      final response = await _apiService.get(
        '/klaimMerchandise/pembeli/$idPembeli',
      );

      developer.log('Klaim merchandise response type: ${response.runtimeType}');
      developer.log('Klaim merchandise response: $response');

      // Handle different response formats
      List<dynamic> dataList;

      if (response is List) {
        // Response is already a list
        dataList = response;
      } else if (response is Map<String, dynamic>) {
        // Response might be wrapped in an object with data field
        if (response.containsKey('data') && response['data'] is List) {
          dataList = response['data'];
        } else if (response.containsKey('success') &&
            response['success'] == true) {
          // Typical API response format
          if (response['data'] is List) {
            dataList = response['data'];
          } else if (response['data'] != null) {
            // Handle single item response
            dataList = [response['data']];
          } else {
            developer.log('Empty data field in success response');
            return [];
          }
        } else {
          developer.log('Unknown response format, cannot extract klaim list');
          return [];
        }
      } else {
        developer.log('Unexpected response format from API');
        return [];
      }

      developer.log('Processing ${dataList.length} klaim items');

      List<KlaimMerchandise> klaimList = [];
      for (var item in dataList) {
        try {
          klaimList.add(KlaimMerchandise.fromJson(item));
        } catch (e) {
          developer.log('Error parsing klaim item: $e');
          developer.log('Item: $item');
        }
      }

      developer.log('Successfully parsed ${klaimList.length} klaim items');
      return klaimList;
    } catch (e) {
      developer.log('Error fetching klaim merchandise: $e');
      throw Exception('Error fetching klaim merchandise: $e');
    }
  }

  // Create new klaim merchandise
  Future<bool> createKlaim(int idPembeli, int idMerchandise) async {
    try {
      developer.log('===== MENCOBA MEMBUAT KLAIM MERCHANDISE =====');
      developer.log('ID Pembeli: $idPembeli, ID Merchandise: $idMerchandise');

      // Data yang diperlukan sesuai dengan validasi di backend
      final Map<String, dynamic> data = {
        'id_pembeli': idPembeli,
        'id_merchandise': idMerchandise,
      };

      developer.log('Data yang dikirim: $data');

      try {
        // Kirim request ke endpoint yang sesuai
        final response = await _apiService.post('/klaimMerchandise', data);

        developer.log('Respons dari server: $response');

        // Jika mendapat respons, anggap berhasil
        if (response != null) {
          developer.log('Klaim berhasil dibuat');
          return true;
        }
      } catch (e) {
        developer.log('Error pada percobaan pertama: $e');

        // Jika gagal, coba dengan format data alternatif
        developer.log('Mencoba dengan format data alternatif...');
        return await _createKlaimAlternatif(idPembeli, idMerchandise);
      }

      developer.log('Gagal membuat klaim: tidak ada respons');
      return false;
    } catch (e) {
      developer.log('Error saat membuat klaim: $e');
      throw Exception('Gagal menukar merchandise: $e');
    }
  }

  // Metode alternatif untuk membuat klaim dengan format data yang berbeda
  Future<bool> _createKlaimAlternatif(int idPembeli, int idMerchandise) async {
    try {
      // Format data alternatif 1
      final Map<String, dynamic> data1 = {
        'pembeli_id': idPembeli,
        'merchandise_id': idMerchandise,
      };

      developer.log('Mencoba format data alternatif 1: $data1');
      try {
        final response = await _apiService.post('/klaimMerchandise', data1);
        if (response != null) {
          developer.log('Berhasil dengan format data alternatif 1');
          return true;
        }
      } catch (e) {
        developer.log('Format data alternatif 1 gagal: $e');
      }

      // Format data alternatif 2 dengan tanggal
      final Map<String, dynamic> data2 = {
        'id_pembeli': idPembeli,
        'id_merchandise': idMerchandise,
        'tanggal_klaim': DateTime.now().toIso8601String().split('T')[0],
        'status_klaim': 'Diproses',
      };

      developer.log('Mencoba format data alternatif 2: $data2');
      try {
        final response = await _apiService.post('/klaimMerchandise', data2);
        if (response != null) {
          developer.log('Berhasil dengan format data alternatif 2');
          return true;
        }
      } catch (e) {
        developer.log('Format data alternatif 2 gagal: $e');
      }

      // Format data alternatif 3 dengan endpoint berbeda
      developer.log('Mencoba dengan endpoint alternatif...');
      try {
        final response = await _apiService.post(
          '/klaimMerchandise/create',
          data2,
        );
        if (response != null) {
          developer.log('Berhasil dengan endpoint alternatif');
          return true;
        }
      } catch (e) {
        developer.log('Endpoint alternatif gagal: $e');
      }

      // Coba dengan direct HTTP request
      developer.log('Mencoba dengan direct HTTP request...');
      final bool directSuccess = await _createKlaimDirectHttp(
        idPembeli,
        idMerchandise,
      );
      if (directSuccess) {
        developer.log('Berhasil dengan direct HTTP request');
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Semua metode alternatif gagal: $e');
      return false;
    }
  }

  // Metode untuk membuat klaim dengan direct HTTP request
  Future<bool> _createKlaimDirectHttp(int idPembeli, int idMerchandise) async {
    try {
      // Ambil token dari local storage
      final token = await LocalStorage.getToken();

      // Coba dengan beberapa URL berbeda
      final List<String> urlsToTry = [
        '${_apiService.baseUrl}/klaimMerchandise',
        '${_apiService.baseUrl}/klaimMerchandise/create',
        'https://api.reusemartuajy.my.id/api/klaimMerchandise',
        'http://10.0.2.2:8000/api/klaimMerchandise',
      ];

      for (final urlString in urlsToTry) {
        try {
          final url = Uri.parse(urlString);
          developer.log('Direct HTTP request ke: $url');

          // Buat headers
          final Map<String, String> headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };

          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }

          // Coba dengan beberapa format data
          final List<Map<String, dynamic>> dataFormats = [
            {'id_pembeli': idPembeli, 'id_merchandise': idMerchandise},
            {'pembeli_id': idPembeli, 'merchandise_id': idMerchandise},
            {
              'id_pembeli': idPembeli,
              'id_merchandise': idMerchandise,
              'tanggal_klaim': DateTime.now().toIso8601String().split('T')[0],
              'status_klaim': 'Diproses',
            },
          ];

          for (final data in dataFormats) {
            try {
              developer.log('Direct HTTP request data: $data');
              developer.log('Direct HTTP request headers: $headers');

              // Kirim request
              final response = await http
                  .post(url, headers: headers, body: json.encode(data))
                  .timeout(const Duration(seconds: 45));

              developer.log(
                'Direct HTTP response status: ${response.statusCode}',
              );
              developer.log('Direct HTTP response body: ${response.body}');

              // Cek status code
              if (response.statusCode == 200 || response.statusCode == 201) {
                developer.log('Direct HTTP request berhasil!');
                return true;
              }
            } catch (dataError) {
              developer.log('Error dengan format data: $dataError');
              // Lanjut ke format data berikutnya
            }
          }
        } catch (urlError) {
          developer.log('Error dengan URL $urlString: $urlError');
          // Lanjut ke URL berikutnya
        }
      }

      // Semua percobaan gagal
      developer.log('Semua percobaan direct HTTP request gagal');
      return false;
    } catch (e) {
      developer.log('Error pada direct HTTP request: $e');
      return false;
    }
  }

  // Get claim by ID
  Future<KlaimMerchandise> getClaimById(int idKlaim) async {
    try {
      developer.log('Fetching claim with ID: $idKlaim');
      final response = await _apiService.get('/klaimMerchandise/$idKlaim');

      developer.log('Get claim response type: ${response.runtimeType}');
      developer.log('Get claim response: $response');

      // Handle different response formats
      Map<String, dynamic> data;

      if (response is Map<String, dynamic>) {
        // Response might be the claim directly
        if (response.containsKey('id_klaim')) {
          data = response;
          developer.log('Direct claim data found');
        }
        // Response might be wrapped in a data field
        else if (response.containsKey('data') && response['data'] is Map) {
          data = response['data'];
          developer.log('Claim data found in data field');
        }
        // Response might be a success/data API format
        else if (response.containsKey('success') &&
            response['success'] == true) {
          if (response['data'] is Map) {
            data = response['data'];
            developer.log('Claim data found in success.data field');
          } else {
            developer.log('Invalid data format in success response');
            throw Exception('Invalid data format in response');
          }
        } else {
          developer.log('Unexpected response structure: $response');
          throw Exception('Unexpected response format');
        }
      } else {
        developer.log('Unexpected response type: ${response.runtimeType}');
        throw Exception('Unexpected response type');
      }

      return KlaimMerchandise.fromJson(data);
    } catch (e) {
      developer.log('Error fetching claim: $e');
      throw Exception('Error fetching claim: $e');
    }
  }

  // Metode publik untuk membuat klaim dengan direct HTTP request
  Future<bool> createKlaimWithDirectHttp(
    int idPembeli,
    int idMerchandise,
  ) async {
    try {
      developer.log('===== MENCOBA MEMBUAT KLAIM DENGAN DIRECT HTTP =====');
      developer.log('ID Pembeli: $idPembeli, ID Merchandise: $idMerchandise');

      return await _createKlaimDirectHttp(idPembeli, idMerchandise);
    } catch (e) {
      developer.log('Error saat membuat klaim dengan direct HTTP: $e');
      return false;
    }
  }
}
