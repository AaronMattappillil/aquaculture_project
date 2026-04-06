// Version: 1.0.1 - AGENT_SYNC_RETRY
// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/alert_service.dart';

class ReportsListScreen extends StatelessWidget {
  final String pondId;
  const ReportsListScreen({super.key, required this.pondId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Reports'),
      ),
      body: ReportsListWidget(pondId: pondId),
    );
  }
}

class ReportsListWidget extends ConsumerWidget {
  final String pondId;
  const ReportsListWidget({super.key, required this.pondId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(userAlertsProvider(pondId));

    return alertsAsync.when(
      data: (alerts) {
        // Filter to only show alerts with CRITICAL or WARNING severity (likely have reports)
        final reports = alerts.where((a) => a.severity != 'SAFE').toList();

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No reports available for this pond.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            // Priority Based Styling
            Color priorityColor = r.severity == 'CRITICAL' ? Colors.red : Colors.orange;
            return Card(
              color: const Color(0xFF112236),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push('/user/alert-report/${r.alertId}'),
                leading: CircleAvatar(
                  backgroundColor: priorityColor.withValues(alpha: 0.2),
                  child: Icon(
                    r.severity == 'CRITICAL' ? Icons.error : Icons.warning,
                    color: priorityColor,
                  ),
                ),
                title: Text(r.alertMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Parameter: ${r.paramName.toUpperCase()} • ${r.paramValue}\n${_formatDate(r.timestamp)}'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading reports: $e')),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
