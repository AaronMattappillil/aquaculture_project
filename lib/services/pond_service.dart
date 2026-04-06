import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pond_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/api_config.dart';

class PondService {
  Future<List<PondModel>> getUserPonds(String token, {String? status}) async {
    String urlStr = '$BASE_URL/ponds';
    if (status != null && status != 'All') {
      urlStr += '?status=${status.toUpperCase()}';
    }

    final url = Uri.parse(urlStr);
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((p) => PondModel.fromJson(p)).toList();
      } else {
        throw Exception('Failed to load ponds: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Pond List Error: $e');
      throw Exception('Failed to load ponds. Please check your connection.');
    }
  }

  Future<PondModel> getPondById(String token, String pondId) async {
    final url = Uri.parse('$BASE_URL/ponds/$pondId');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return PondModel.fromJson(jsonDecode(response.body));
      } else {
        if (response.statusCode == 404) {
          throw Exception('Pond not found');
        } else {
          throw Exception('Failed to load pond: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Pond Detail Error: $e');
      throw Exception('Failed to load pond details.');
    }
  }

  Future<PondModel> createPond(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$BASE_URL/ponds');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PondModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create pond: ${response.body}');
      }
    } catch (e) {
      debugPrint('Pond Create Error: $e');
      throw Exception('Failed to create pond. Check connection.');
    }
  }

  Future<PondModel> updatePond(String token, String pondId, Map<String, dynamic> data) async {
    final url = Uri.parse('$BASE_URL/ponds/$pondId');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return PondModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update pond');
      }
    } catch (e) {
      debugPrint('Pond Update Error: $e');
      throw Exception('Failed to update pond.');
    }
  }

  Future<void> deletePond(String token, String pondId) async {
    final url = Uri.parse('$BASE_URL/ponds/$pondId');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(API_TIMEOUT);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete pond: ${response.body}');
      }
    } catch (e) {
      debugPrint('Pond Delete Error: $e');
      throw Exception('Failed to delete pond.');
    }
  }
}


final pondServiceProvider = Provider((ref) => PondService());
