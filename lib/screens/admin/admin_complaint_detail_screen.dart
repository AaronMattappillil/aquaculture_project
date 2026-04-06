// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/support_ticket_model.dart';
import '../../services/support_ticket_service.dart';
import '../../services/admin_service.dart';
import '../../app.dart';
import 'package:intl/intl.dart';
import 'admin_users_screen.dart';

class AdminComplaintDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const AdminComplaintDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<AdminComplaintDetailScreen> createState() => _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState extends ConsumerState<AdminComplaintDetailScreen> {
  SupportTicketModel? _ticket;
  String? _userName;
  bool _isLoading = true;
  bool _isResolving = false;
  String? _error;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final ticket = await ref.read(supportTicketServiceProvider).getTicketById(token, widget.ticketId);
      
      // Fetch user name
      String? userName;
      try {
        final profile = await ref.read(adminServiceProvider).getUserDetail(token, ticket.userId);
        userName = '${profile.user.firstName} ${profile.user.lastName}';
      } catch (e) {
        userName = "Unknown User";
      }

        setState(() {
          _ticket = ticket;
          _userName = userName;
          _isLoading = false;
          if (ticket.adminResponse != null) {
            _responseController.text = ticket.adminResponse!;
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveComplaint() async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a response for the customer')));
      return;
    }

    setState(() => _isResolving = true);
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      await ref.read(supportTicketServiceProvider).resolveTicket(token, widget.ticketId, _responseController.text);
      
      // Invalidate providers to force refresh on main admin screens
      ref.invalidate(adminTicketsProvider(null));
      ref.invalidate(adminTicketsProvider('open'));
      ref.invalidate(adminTicketsProvider('resolved'));
      ref.invalidate(adminDashboardProvider);

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket marked as resolved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resolving ticket: $e')));
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final t = _ticket!;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isResolved = t.status.toLowerCase() == 'resolved';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Customer Care Details'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              t.status.toUpperCase(),
              style: TextStyle(
                color: isResolved ? Colors.green : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF112236),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 24, backgroundColor: Color(0xFF0E6E8A), child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text('User Info', style: TextStyle(fontSize: 10, color: Colors.grey)),
                           Text(_userName ?? 'Loading...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                           Text('User ID: ${t.userId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                           if (t.pondId != null) 
                             Text('Pond ID: ${t.pondId}', style: const TextStyle(color: Color(0xFF0E6E8A), fontSize: 11, fontWeight: FontWeight.bold)),
                           Text('Ticket ID: #${t.ticketId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF112236),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket Description', style: TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Submitted: ${dateFormat.format(t.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    const Text('SUBJECT', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(t.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('MESSAGE', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(t.message, style: const TextStyle(height: 1.5, color: Colors.white70)),
                  ]
                ),
              ),
            ),
            if (isResolved) ...[
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF0E6E8A).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.support_agent, color: Color(0xFF0E6E8A)),
                          SizedBox(width: 8),
                          Text('Support Response', style: TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(t.adminResponse ?? _responseController.text, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              )
            ] else ...[
              const SizedBox(height: 24),
              const Text('Admin Response & Notes', style: TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF112236),
                  border: OutlineInputBorder(),
                  hintText: 'Internal Notes...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _responseController,
                maxLines: 4,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF112236),
                  border: OutlineInputBorder(),
                  hintText: 'Response to Customer...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!isResolved)
              ElevatedButton.icon(
                icon: _isResolving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(_isResolving ? 'Resolving...' : 'Mark as Resolved', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isResolving ? null : _resolveComplaint,
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text('This ticket has been resolved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}
