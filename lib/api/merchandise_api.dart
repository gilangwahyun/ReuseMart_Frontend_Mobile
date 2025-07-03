import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/merchandise_model.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class MerchandiseApi {
  final ApiService _apiService = ApiService();

  // Get all merchandise
  Future<List<Merchandise>> getAllMerchandise() async {
    try {
      developer.log('Fetching all merchandise');
      final response = await _apiService.get('/merchandise');

      developer.log('Merchandise response type: ${response.runtimeType}');
      developer.log('Merchandise response: $response');

      // Handling various response formats
      List<dynamic> dataList;

      if (response is List) {
        // Response is already a list
        dataList = response;
      } else if (response is Map<String, dynamic>) {
        // Response is wrapped in an object
        if (response.containsKey('data') && response['data'] is List) {
          dataList = response['data'];
        } else if (response.containsKey('success') &&
            response['success'] == true) {
          // Typical API response format
          if (response['data'] is List) {
            dataList = response['data'];
          } else {
            // Handle single item response
            dataList = [response['data']];
          }
        } else {
          // Unknown format
          developer.log(
            'Unknown response format, cannot extract merchandise list',
          );
          return [];
        }
      } else {
        developer.log('Unexpected response format from API');
        return [];
      }

      developer.log('Processing ${dataList.length} merchandise items');

      List<Merchandise> merchandiseList = [];
      for (var item in dataList) {
        try {
          merchandiseList.add(Merchandise.fromJson(item));
        } catch (e) {
          developer.log('Error parsing merchandise item: $e');
          developer.log('Item: $item');
        }
      }

      developer.log(
        'Successfully parsed ${merchandiseList.length} merchandise items',
      );
      return merchandiseList;
    } catch (e) {
      developer.log('Error fetching merchandise: $e');
      throw Exception('Error fetching merchandise: $e');
    }
  }

  // Get merchandise by ID
  Future<Merchandise> getMerchandiseById(int id) async {
    try {
      developer.log('Fetching merchandise with ID: $id');
      final response = await _apiService.get('/merchandise/$id');

      // Handle different response formats
      Map<String, dynamic> data;

      if (response is Map<String, dynamic>) {
        // Response might be the merchandise directly
        if (response.containsKey('id_merchandise')) {
          data = response;
        }
        // Response might be wrapped in a data field
        else if (response.containsKey('data') && response['data'] is Map) {
          data = response['data'];
        }
        // Response might be a success/data API format
        else if (response.containsKey('success') &&
            response['success'] == true) {
          if (response['data'] is Map) {
            data = response['data'];
          } else {
            throw Exception('Invalid data format in response');
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Unexpected response type');
      }

      return Merchandise.fromJson(data);
    } catch (e) {
      developer.log('Error fetching merchandise by ID: $e');
      throw Exception('Error fetching merchandise: $e');
    }
  }
}
