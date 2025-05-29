import 'api_service.dart';

class DetailTransaksiApi {
  final ApiService _apiService = ApiService();

  Future<dynamic> getDetailTransaksiByTransaksi(int idTransaksi) async {
    try {
      print('API call: Getting details for transaction ID: $idTransaksi');

      final response = await _apiService.get(
        '/detailTransaksi/transaksi/$idTransaksi',
      );

      print('Response from API: $response');
      return response;
    } catch (error) {
      print('Error fetching transaction details: $error');
      return []; // Return empty array on error
    }
  }
}
