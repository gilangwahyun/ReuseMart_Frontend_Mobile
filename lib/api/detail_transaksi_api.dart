import 'api_service.dart';
import '../models/detail_transaksi_model.dart';

class DetailTransaksiApi {
  final ApiService _apiService = ApiService();

  Future<List<DetailTransaksiModel>> getDetailTransaksiByTransaksi(int idTransaksi) async {
    try {
      print('API call: Getting details for transaction ID: $idTransaksi');

      final response = await _apiService.get(
        '/detailTransaksi/transaksi/$idTransaksi',
      );

      print('Response from API: $response');
      
      if (response is List) {
        return response.map((item) => DetailTransaksiModel.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map && response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => DetailTransaksiModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (error) {
      print('Error fetching transaction details: $error');
      return []; // Return empty array on error
    }
  }
  
  Future<DetailTransaksiModel?> getDetailTransaksiById(int idDetailTransaksi) async {
    try {
      print('API call: Getting detail transaksi by ID: $idDetailTransaksi');
      
      final response = await _apiService.get('/detailTransaksi/$idDetailTransaksi');
      
      if (response != null) {
        if (response is Map) {
          if (response.containsKey('data')) {
            return DetailTransaksiModel.fromJson(response['data'] as Map<String, dynamic>);
          } else {
            return DetailTransaksiModel.fromJson(response as Map<String, dynamic>);
          }
        }
      }
      
      return null;
    } catch (error) {
      print('Error fetching transaction detail: $error');
      return null;
    }
  }
}
