import 'api_service.dart';

class RequestDonasiApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/requestDonasi';

  Future<dynamic> getAllRequestDonasi() async {
    try {
      print('Fetching all request donasi');
      final response = await _apiService.get(apiUrl);

      if (response == null) {
        print('Invalid response from getAllRequestDonasi: $response');
        return [];
      }

      return response;
    } catch (error) {
      print('Error fetching all request donasi: $error');
      return [];
    }
  }

  Future<dynamic> createRequestDonasi(Map<String, dynamic> data) async {
    try {
      print('Creating request donasi with data: $data');
      final response = await _apiService.post(apiUrl, data);
      return response;
    } catch (error) {
      print('Error creating request donasi: $error');
      throw error;
    }
  }

  Future<dynamic> getRequestDonasiByOrganisasi(int idOrganisasi) async {
    try {
      if (idOrganisasi == 0) {
        print('Missing idOrganisasi in getRequestDonasiByOrganisasi');
        return [];
      }

      print('Fetching request donasi for organisasi $idOrganisasi');
      final response = await _apiService.get(
        '$apiUrl/organisasi/$idOrganisasi',
      );

      if (response == null) {
        print('Invalid response for organisasi $idOrganisasi: $response');
        return [];
      }

      print(
        'Retrieved ${response.length} request records for organisasi $idOrganisasi',
      );
      return response;
    } catch (error) {
      print(
        'Error fetching request donasi for organisasi $idOrganisasi: $error',
      );
      return [];
    }
  }

  Future<dynamic> deleteRequestDonasi(int id) async {
    try {
      print('Deleting request donasi $id');
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      print('Error deleting request donasi $id: $error');
      throw error;
    }
  }

  Future<dynamic> updateRequestDonasi(int id, Map<String, dynamic> data) async {
    try {
      print('Updating request donasi $id with data: $data');
      final response = await _apiService.put('$apiUrl/$id', data);
      return response;
    } catch (error) {
      print('Error updating request donasi $id: $error');
      throw error;
    }
  }

  Future<dynamic> updateRequestDonasiByOrganisasi(
    int idOrganisasi,
    int idRequestDonasi,
    Map<String, dynamic> data,
  ) async {
    try {
      print(
        'Updating request donasi $idRequestDonasi for organisasi $idOrganisasi with data: $data',
      );
      final response = await _apiService.put(
        '$apiUrl/organisasi/$idOrganisasi/$idRequestDonasi',
        data,
      );
      return response;
    } catch (error) {
      print(
        'Error updating request donasi $idRequestDonasi for organisasi $idOrganisasi: $error',
      );
      throw error;
    }
  }

  Future<dynamic> deleteRequestDonasiByOrganisasi(
    int idOrganisasi,
    int idRequestDonasi,
  ) async {
    try {
      print(
        'Deleting request donasi $idRequestDonasi for organisasi $idOrganisasi',
      );
      final response = await _apiService.delete(
        '$apiUrl/organisasi/$idOrganisasi/$idRequestDonasi',
      );
      return response;
    } catch (error) {
      print(
        'Error deleting request donasi $idRequestDonasi for organisasi $idOrganisasi: $error',
      );
      throw error;
    }
  }

  Future<dynamic> createRequestDonasiByOrganisasi(
    int idOrganisasi,
    Map<String, dynamic> data,
  ) async {
    try {
      print(
        'Creating request donasi for organisasi $idOrganisasi with data: $data',
      );
      final response = await _apiService.post(
        '$apiUrl/organisasi/$idOrganisasi',
        data,
      );
      return response;
    } catch (error) {
      print(
        'Error creating request donasi for organisasi $idOrganisasi: $error',
      );
      throw error;
    }
  }
}
