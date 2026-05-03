import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Model/Support/support_ticket_model.dart';

class SupportRepository {
  static const String baseUrl = "https://edu-ai-backend-vl7s.onrender.com/support/tickets";
  static const String apiKey = "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c";

  /// GET All Support Tickets via API
  Future<List<SupportTicket>> getAllTickets() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportTicket.fromJson(json)).toList();
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching support tickets via API: $e");
      return [];
    }
  }

  /// UPDATE Ticket Response via API
  Future<bool> updateTicketResponse(String ticketId, String responseText) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/$ticketId"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({'adminResponse': responseText}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating ticket response via API: $e");
      return false;
    }
  }

  /// GET User Support Tickets via API
  Future<List<SupportTicket>> getUserTickets(String email) async {
    try {
      final response = await http.get(
        Uri.parse("https://edu-ai-backend-main.onrender.com/support/tickets/user/$email"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportTicket.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching user tickets: $e");
      return [];
    }
  }

  /// UPDATE Ticket Status via API
  Future<bool> updateTicketStatus(String ticketId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/$ticketId"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating ticket status via API: $e");
      return false;
    }
  }

  /// ADD REPLY to Ticket
  Future<bool> addTicketReply(String ticketId, String reply) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/$ticketId"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'reply': reply,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error adding ticket reply: $e");
      return false;
    }
  }

  /// UPDATE Ticket Hardware Details via API
  Future<bool> updateTicketHardwareDetails(String ticketId, bool isHardware, String? trackingLink, {String? manualTrackingStatus}) async {
    try {
      final Map<String, dynamic> body = {
        'isHardwareComplaint': isHardware,
        'trackingLink': trackingLink,
      };
      if (manualTrackingStatus != null) {
        body['manualTrackingStatus'] = manualTrackingStatus;
      }
      
      final response = await http.patch(
        Uri.parse("$baseUrl/$ticketId"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating ticket hardware details via API: $e");
      return false;
    }
  }

  /// Stream of tickets for real-time updates (Polled via API)
  Stream<List<SupportTicket>> getTicketsStream() async* {
    while (true) {
      yield await getAllTickets();
      await Future.delayed(const Duration(seconds: 10)); // Poll every 10 seconds
    }
  }

  /// CREATE Ticket via API
  Future<bool> createTicket({
    required String email,
    required String message,
    String contactNumber = "",
    bool isHardware = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'email': email,
          'message': message,
          'contactNumber': contactNumber,
          'chatHistory': 'Ticket raised via Admin Panel',
          'status': 'open',
          'isHardwareComplaint': isHardware,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error creating ticket via API: $e");
      return false;
    }
  }
}
