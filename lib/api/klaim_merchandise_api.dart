import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/klaim_merchandise_model.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class KlaimMerchandiseApi {
  final ApiService _apiService = ApiService();

  // Get klaim merchandise by pembeli ID
  Future<List<KlaimMerchandise>> getByPembeli(int idPembeli) async {
    try {
      final response = await _apiService.get('/klaimMerchandise/pembeli/$idPembeli');
      
      // ApiService already parsed the JSON, so we work with the parsed data directly
      if (response is List) {
        return response.map((item) => KlaimMerchandise.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching klaim merchandise: $e');
    }
  }

  // Create new klaim merchandise with tanggal_klaim
  Future<KlaimMerchandise> createKlaim(int idPembeli, int idMerchandise) async {
    try {
      // Step 1: Create the initial claim
      final Map<String, dynamic> data = {
        'id_pembeli': idPembeli,
        'id_merchandise': idMerchandise,
      };

      final response = await _apiService.post(
        '/klaimMerchandise',
        data,
      );
      
      // Check if the creation was successful
      if (response is Map<String, dynamic>) {
        final claim = KlaimMerchandise.fromJson(response);
        developer.log('Claim created with ID: ${claim.idKlaim}');
        
        try {
          // Step 2: Make a direct HTTP request to set the date without changing status
          // We'll use a raw HTTP request to have more control over the format
          final formattedDate = DateTime.now().toIso8601String().split('T')[0];
          developer.log('Setting tanggal_klaim to: $formattedDate');
          
          // Make a direct database update using a custom endpoint
          // Note: You'll need to create this endpoint in your backend
          await _updateClaimDateDirect(claim.idKlaim, formattedDate);
          
          // Return the updated claim
          return await getClaimById(claim.idKlaim);
        } catch (updateError) {
          developer.log('Error updating claim date: $updateError');
          // Even if the date update fails, still return the created claim
          return claim;
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error creating klaim: $e');
    }
  }
  
  // Direct update of claim date using raw SQL (requires backend endpoint)
  Future<void> _updateClaimDateDirect(int idKlaim, String date) async {
    try {
      final Map<String, dynamic> data = {
        'id_klaim': idKlaim,
        'tanggal_klaim': date,
      };
      
      // This assumes you've created a special endpoint just for updating the date
      await _apiService.post(
        '/klaimMerchandise/update-date',
        data,
      );
    } catch (e) {
      developer.log('Error in direct date update: $e');
      throw e;
    }
  }
  
  // Get claim by ID
  Future<KlaimMerchandise> getClaimById(int idKlaim) async {
    try {
      final response = await _apiService.get('/klaimMerchandise/$idKlaim');
      
      if (response is Map<String, dynamic>) {
        return KlaimMerchandise.fromJson(response);
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching claim: $e');
    }
  }
} 