import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/support_ticket_service.dart';

import '../../app.dart';
import '../../models/support_ticket_model.dart';

final ticketDetailProvider = FutureProvider.family<SupportTicketModel, String>((ref, String ticketId) {
  final user = ref.watch(authStateProvider);
  final token = user?.accessToken ?? '';
  return ref.watch(supportTicketServiceProvider).getTicketById(token, ticketId);
});

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Ticket Details'),
      ),
      body: ticketAsync.when(
        data: (ticket) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF112236),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ticket ID: ${ticket.ticketId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ticket.status == 'RESOLVED' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(ticket.status, style: TextStyle(fontSize: 10, color: ticket.status == 'RESOLVED' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(ticket.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Category: ${ticket.category}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Text('MESSAGE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(ticket.message, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              ),
              
              if(ticket.adminResponse != null) ...[
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
                        Text(ticket.adminResponse!, style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  ),
                )
              ]
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load ticket details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString().contains('404') 
                    ? 'Ticket not found. It may have been deleted.' 
                    : 'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(ticketDetailProvider(ticketId)),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
