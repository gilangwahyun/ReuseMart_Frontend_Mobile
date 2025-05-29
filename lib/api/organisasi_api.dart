import 'api_service.dart';

class OrganisasiApi {
  final ApiService _apiService = ApiService();
  final String apiUrl = '/organisasi';

  Future<dynamic> createOrganisasi(Map<String, dynamic> userData) async {
    try {
      print('Creating organisasi with data: $userData');
      final response = await _apiService.post(apiUrl, userData);
      return response;
    } catch (error) {
      print('Error creating organisasi: $error');
      throw error;
    }
  }

  Future<dynamic> getOrganisasi() async {
    try {
      print('Fetching all organisasi data');
      final response = await _apiService.get(apiUrl);

      // Validate the response
      if (response == null) {
        print('Invalid response from getOrganisasi: $response');
        return [];
      }

      print('Retrieved ${response.length} organisasi records');
      return response;
    } catch (error) {
      print('Error fetching organisasi: $error');
      // Return empty array instead of throwing to prevent component crashes
      return [];
    }
  }

  Future<dynamic> updateOrganisasi(
    int id,
    Map<String, dynamic> organisasiData,
  ) async {
    try {
      print('Updating organisasi $id with data: $organisasiData');
      final response = await _apiService.put('$apiUrl/$id', organisasiData);
      return response;
    } catch (error) {
      print('Error updating organisasi $id: $error');
      throw error;
    }
  }

  Future<dynamic> getOrganisasiById(int id) async {
    try {
      print('Fetching organisasi with id $id');
      final response = await _apiService.get('$apiUrl/$id');
      return response;
    } catch (error) {
      print('Error fetching organisasi $id: $error');
      throw error;
    }
  }

  Future<dynamic> deleteOrganisasi(int id) async {
    try {
      print('Deleting organisasi with id $id');
      final response = await _apiService.delete('$apiUrl/$id');
      return response;
    } catch (error) {
      print('Error deleting organisasi $id: $error');
      throw error;
    }
  }

  Future<dynamic> getOrganisasiWithoutRequest() async {
    try {
      print('Fetching organisasi without requests');
      final response = await _apiService.get('$apiUrl/without-request');

      // Validate the response
      if (response == null) {
        print('Invalid response from getOrganisasiWithoutRequest: $response');
        return [];
      }

      return response;
    } catch (error) {
      print('Error fetching organisasi without requests: $error');
      // Return empty array instead of throwing
      return [];
    }
  }
}
