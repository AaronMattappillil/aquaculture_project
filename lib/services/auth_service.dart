import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  Future<UserModel?> login(String username, String password) async {
    final url = Uri.parse('$BASE_URL/auth/login-json');
    debugPrint('Requesting: $url');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel(
          id: data['id'] ?? '',
          role: data['role'] ?? 'farmer',
          username: username,
          email: '',
          firstName: '',
          lastName: '',
          status: 'active',
          accessToken: data['access_token'] ?? '',
        );
        await _saveSession(user);
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Invalid credentials');
      }
    } catch (e) {
      debugPrint('Login Network Error: $e');
      throw Exception('Authentication failed. Please check your connection or try again.');
    }
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', jsonEncode({
      'id': user.id,
      'username': user.username,
      'role': user.role,
      'access_token': user.accessToken,
    }));
  }

  Future<UserModel?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_json');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_json');
  }

  Future<void> signup(Map<String, dynamic> payload) async {
    final url = Uri.parse('$BASE_URL/auth/register');
    debugPrint('Requesting: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(API_TIMEOUT);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Signup Network Error: $e');
      throw Exception('Registration failed. Please check your connection.');
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());
