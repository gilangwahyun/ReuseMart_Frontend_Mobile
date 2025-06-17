import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/merchandise_model.dart';
import 'api_service.dart';

class MerchandiseApi {
  final ApiService _apiService = ApiService();

  // Get all merchandise
  Future<List<Merchandise>> getAllMerchandise() async {
    try {
      final response = await _apiService.get('/merchandise');
      
      // ApiService already parsed the JSON, so we work with the parsed data directly
      if (response is List) {
        return response.map((item) => Merchandise.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching merchandise: $e');
    }
  }

  // Get merchandise by ID
  Future<Merchandise> getMerchandiseById(int id) async {
    try {
      final response = await _apiService.get('/merchandise/$id');
      
      // ApiService already parsed the JSON, so we work with the parsed data directly
      if (response is Map<String, dynamic>) {
        return Merchandise.fromJson(response);
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching merchandise: $e');
    }
  }
} 