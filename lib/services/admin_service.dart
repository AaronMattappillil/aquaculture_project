import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/admin_model.dart';
import '../app.dart';
import '../config/api_config.dart';

class AdminService {
  Future<List<AdminUserSummary>> getAdminUsers(String token, {String? search}) async {
    String urlStr = '$BASE_URL/admin/users';
    if (search != null && search.isNotEmpty) {
      urlStr += '?search=$search';
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
        return data.map((x) => AdminUserSummary.fromJson(x)).toList();
      } else {
        throw Exception('Failed to load admin users: ${response.body}');
      }
    } catch (e) {
      debugPrint('Admin Users Error: $e');
      throw Exception('Failed to load users. Check connection.');
    }
  }

  Future<AdminUserDetail> getUserDetail(String token, String userId) async {
    final url = Uri.parse('$BASE_URL/admin/users/$userId');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return AdminUserDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load user detail: ${response.body}');
      }
    } catch (e) {
      debugPrint('Admin User Detail Error: $e');
      throw Exception('Failed to load user detail.');
    }
  }

  Future<void> deleteUser(String token, String userId) async {
    final url = Uri.parse('$BASE_URL/admin/users/$userId');
    debugPrint('Requesting: $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      debugPrint('Admin Delete User Error: $e');
      throw Exception('Failed to delete user.');
    }
  }

  Future<AdminUserProfile> updateUserStatus(String token, String userId, String status) async {
    final url = Uri.parse('$BASE_URL/admin/users/$userId/status');
    debugPrint('Requesting: $url');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return AdminUserProfile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update user status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Admin Update Status Error: $e');
      throw Exception('Failed to update user status.');
    }
  }

  Future<AdminDashboardModel> getAdminDashboard(String token) async {
    final url = Uri.parse('$BASE_URL/admin/dashboard');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return AdminDashboardModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load admin dashboard: ${response.body}');
      }
    } catch (e) {
      debugPrint('Admin Dashboard Error: $e');
      throw Exception('Failed to load dashboard. Check connection.');
    }
  }
}

final adminServiceProvider = Provider((ref) => AdminService());

final adminDashboardProvider = FutureProvider<AdminDashboardModel>((ref) async {
  final token = ref.read(authStateProvider)?.accessToken ?? '';
  return ref.read(adminServiceProvider).getAdminDashboard(token);
});
