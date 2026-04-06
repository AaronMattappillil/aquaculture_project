import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/fish_species_model.dart';
import '../config/api_config.dart';

class FishSpeciesService {
  Future<List<FishSpeciesModel>> getFishSpecies() async {
    final url = Uri.parse('$BASE_URL/fish-species');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.get(url).timeout(API_TIMEOUT);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FishSpeciesModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load fish species: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get Fish Species Error: $e');
      throw Exception('Failed to load fish species. Check connection.');
    }
  }

  Future<FishSpeciesModel> createFishSpecies(FishSpeciesModel species) async {
    final url = Uri.parse('$BASE_URL/fish-species');
    debugPrint('Requesting: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(species.toJson()),
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FishSpeciesModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create fish species: ${response.body}');
      }
    } catch (e) {
      debugPrint('Create Fish Species Error: $e');
      throw Exception('Failed to create fish species.');
    }
  }

  Future<void> deleteFishSpecies(String speciesId) async {
    final url = Uri.parse('$BASE_URL/fish-species/$speciesId');
    debugPrint('Requesting: $url');

    try {
      await http.delete(url).timeout(API_TIMEOUT);
    } catch (e) {
      debugPrint('Delete Fish Species Error: $e');
    }
  }
}

final fishSpeciesServiceProvider = Provider((ref) => FishSpeciesService());

final fishSpeciesProvider = FutureProvider<List<FishSpeciesModel>>((ref) async {
  return ref.watch(fishSpeciesServiceProvider).getFishSpecies();
});
