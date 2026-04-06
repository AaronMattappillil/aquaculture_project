import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../models/report_model.dart';
import '../app.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/api_config.dart';

class AlertService {
  /// Periodic stream that polls the REST API every 30 seconds.
  Stream<List<AlertModel>> alertsStream({String? pondId}) async* {
    while (true) {
      try {
        final user = _cachedUser;
        if (user != null) {
          final alerts = await getUserAlerts(user.accessToken, pondId: pondId);
          yield alerts;
        }
      } catch (_) {
        // Keep stream alive
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  _UserRef? _cachedUser;

  Future<void> markAsRead(String token, String alertId) async {
    final url = Uri.parse('$BASE_URL/alerts/$alertId');
    debugPrint('Requesting: $url');
    
    try {
      await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_read': true}),
      ).timeout(API_TIMEOUT);
    } catch (e) {
      debugPrint('Mark Alert Read Error: $e');
    }
  }

  Future<List<AlertModel>> getUserAlerts(String token, {String? pondId}) async {
    var urlStr = '$BASE_URL/alerts';
    if (pondId != null) {
      urlStr += '?pond_id=$pondId';
    }
    
    final url = Uri.parse(urlStr);
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => AlertModel.fromJson(a)).toList();
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      debugPrint('Alert List Error: $e');
      throw Exception('Failed to load alerts. Check connection.');
    }
  }

  Future<AlertModel> getAlertById(String token, String alertId) async {
    final url = Uri.parse('$BASE_URL/alerts/$alertId');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return AlertModel.fromJson(jsonDecode(response.body));
      } else {
        final alerts = await getUserAlerts(token);
        return alerts.firstWhereOrNull((a) => a.alertId == alertId) ??
            (throw Exception('Alert not found'));
      }
    } catch (e) {
      debugPrint('Alert Detail Error: $e');
      throw Exception('Failed to load alert details.');
    }
  }

  Future<void> updateAlert(String token, String alertId, Map<String, dynamic> data) async {
    final url = Uri.parse('$BASE_URL/alerts/$alertId');
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
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update alert');
      }
    } catch (e) {
      debugPrint('Update Alert Error: $e');
      throw Exception('Failed to update alert.');
    }
  }

  Future<ReportModel?> getReportByAlertId(String token, String alertId) async {
    final url = Uri.parse('$BASE_URL/reports/alert/$alertId');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return ReportModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load report');
      }
    } catch (e) {
      debugPrint('Get Report Error: $e');
      return null;
    }
  }
}

/// Simple holder so the polling stream inside AlertService
/// can access the current user's token without needing a Ref.
class _UserRef {
  final String accessToken;
  const _UserRef(this.accessToken);
}

final alertServiceProvider = Provider((ref) => AlertService());

final userAlertsProvider = FutureProvider.family<List<AlertModel>, String?>((ref, pondId) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  final token = user.accessToken;
  return ref.watch(alertServiceProvider).getUserAlerts(token, pondId: pondId);
});

final alertByIdProvider = FutureProvider.family<AlertModel, String>((ref, alertId) async {
  final user = ref.watch(authStateProvider);
  if (user == null) throw Exception('Not authenticated');
  return ref.watch(alertServiceProvider).getAlertById(user.accessToken, alertId);
});

final alertsStreamProvider = StreamProvider.family<List<AlertModel>, String?>((ref, pondId) {
  final user = ref.watch(authStateProvider);
  final service = ref.watch(alertServiceProvider);
  // Inject current user so the polling loop inside alertsStream can use the token
  if (user != null) {
    service._cachedUser = _UserRef(user.accessToken);
  }
  return service.alertsStream(pondId: pondId);
});

final reportByAlertIdProvider = FutureProvider.family<ReportModel?, String>((ref, alertId) async {
  final user = ref.watch(authStateProvider);
  if (user == null) throw Exception('Not authenticated');
  return ref.watch(alertServiceProvider).getReportByAlertId(user.accessToken, alertId);
});
