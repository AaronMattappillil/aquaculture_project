import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading_model.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../app.dart';
import '../config/api_config.dart';

/// SensorService is the single entry-point for sensor data in the Flutter app.
class SensorService {
  Stream<SensorReadingModel> getLiveSensorData(String token, String pondId) async* {
    while (true) {
      final url = Uri.parse('$baseUrl/sensors/ponds/$pondId/latest');
      debugPrint('Requesting: $url');
      
      try {
        final response = await http.get(
          url,
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(API_TIMEOUT);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          yield SensorReadingModel.fromJson(data);
        } else if (response.statusCode == 404) {
          debugPrint('No latest reading found for pond $pondId (404)');
        }
      } catch (e) {
        debugPrint('Polling Exception for pond $pondId: $e');
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<SensorReadingModel>> getHistoricalData(String token, String pondId) async {
    final url = Uri.parse('$baseUrl/sensors/ponds/$pondId/history');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((s) => SensorReadingModel.fromJson(s)).toList();
      } else {
        throw Exception('Failed to load sensor history');
      }
    } catch (e) {
      debugPrint('Sensor History Error: $e');
      throw Exception('Failed to load sensor history. Check connection.');
    }
  }
}

final sensorServiceProvider = Provider((ref) => SensorService());

final liveSensorProvider = StreamProvider.family<SensorReadingModel, String>((ref, pondId) {
  final user = ref.watch(authStateProvider);
  final token = user?.accessToken ?? '';
  return ref.watch(sensorServiceProvider).getLiveSensorData(token, pondId);
});
