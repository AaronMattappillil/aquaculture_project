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
  // Static cache to retain the last known reading per pond ID
  static final Map<String, SensorReadingModel> _lastReadings = {};

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
          final reading = SensorReadingModel.fromJson(data);
          
          // Update cache
          _lastReadings[pondId] = reading;
          yield reading;
        } else if (response.statusCode == 404) {
          debugPrint('No latest reading found for pond $pondId (404)');
          // If we have a cached reading, yield it even if the server says 404
          if (_lastReadings.containsKey(pondId)) {
            yield _lastReadings[pondId]!;
          }
        }
      } catch (e) {
        debugPrint('Polling Exception for pond $pondId: $e');
        // Fallback to cached reading on network/timeout error
        if (_lastReadings.containsKey(pondId)) {
          yield _lastReadings[pondId]!;
        }
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
        final list = data.map((s) => SensorReadingModel.fromJson(s)).toList();
        
        // Update latest cache if history has new data
        if (list.isNotEmpty) {
          _lastReadings[pondId] = list.first;
        }
        return list;
      } else {
        // Fallback to cache if server fails
        if (_lastReadings.containsKey(pondId)) {
          return [_lastReadings[pondId]!];
        }
        throw Exception('Failed to load sensor history');
      }
    } catch (e) {
      debugPrint('Sensor History Error: $e');
      // Fallback to cache if network fails
      if (_lastReadings.containsKey(pondId)) {
        return [_lastReadings[pondId]!];
      }
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
