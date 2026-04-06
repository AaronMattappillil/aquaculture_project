import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/api_config.dart';

class SupportTicketService {
  Future<List<SupportTicketModel>> getUserTickets(String token, {String? userId, String? status}) async {
    var urlStr = '$BASE_URL/support/tickets';
    List<String> params = [];
    if (status != null) params.add('status=$status');

    if (params.isNotEmpty) {
      urlStr += '?${params.join('&')}';
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
        return data.map((x) => SupportTicketModel.fromJson(x)).toList();
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      debugPrint('Get Tickets Error: $e');
      throw Exception('Failed to load tickets. Check connection.');
    }
  }

  Future<List<Map<String, dynamic>>> getTicketAlerts(String token, String ticketId) async {
    final url = Uri.parse('$BASE_URL/support/tickets/$ticketId/alerts');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load ticket alerts');
      }
    } catch (e) {
      debugPrint('Get Ticket Alerts Error: $e');
      throw Exception('Failed to load ticket alerts.');
    }
  }

  Future<SupportTicketModel> getTicketById(String token, String ticketId) async {
    final url = Uri.parse('$BASE_URL/support/tickets/$ticketId');
    debugPrint('Requesting: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return SupportTicketModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load ticket details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get Ticket Detail Error: $e');
      throw Exception('Failed to load ticket details.');
    }
  }

  Future<void> createTicket({
    required String token,
    required String category,
    required String subject,
    required String description,
    String? pondId,
  }) async {
    final url = Uri.parse('$BASE_URL/support/tickets');
    debugPrint('Requesting: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category': category,
          'subject': subject,
          'description': description,
          'pond_id': pondId,
        }),
      ).timeout(API_TIMEOUT);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create ticket: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Create Ticket Error: $e');
      throw Exception('Failed to create ticket. Check connection.');
    }
  }

  Future<void> resolveTicket(String token, String ticketId, String adminResponse) async {
    final url = Uri.parse('$BASE_URL/support/tickets/$ticketId/resolve');
    debugPrint('Requesting: $url');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'admin_response': adminResponse,
        }),
      ).timeout(API_TIMEOUT);

      if (response.statusCode != 200) {
        throw Exception('Failed to resolve ticket: ${response.body}');
      }
    } catch (e) {
      debugPrint('Resolve Ticket Error: $e');
      throw Exception('Failed to resolve ticket.');
    }
  }
}

final supportTicketServiceProvider = Provider((ref) => SupportTicketService());
