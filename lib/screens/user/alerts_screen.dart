import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/alert_service.dart';
import '../../models/alert_model.dart';
import 'ponds_list_screen.dart';
import '../../app.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('System Alerts'),
      ),
      body: const AlertsWidget(),
    );
  }
}

class AlertsWidget extends ConsumerStatefulWidget {
  final String? pondId;
  const AlertsWidget({super.key, this.pondId});

  @override
  ConsumerState<AlertsWidget> createState() => _AlertsWidgetState();
}

class _AlertsWidgetState extends ConsumerState<AlertsWidget> {
  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsStreamProvider(widget.pondId));
    final pondsAsync = ref.watch(pondsFutureProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            indicatorColor: Color(0xFF00BFFF),
            labelColor: Color(0xFF00BFFF),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'UNREAD'),
              Tab(text: 'READ'),
            ],
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: alertsAsync.when(
              data: (alerts) {
                final filtered = alerts.where((a) => a.pondId == '69cec3ae6fca89e082227165').toList();
                return TabBarView(
                  children: [
                    _buildAlertsList(filtered.where((a) => !a.isRead).toList(), pondsAsync),
                    _buildAlertsList(filtered.where((a) => a.isRead).toList(), pondsAsync),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<AlertModel> alerts, AsyncValue<List<dynamic>> pondsAsync) {
    if (alerts.isEmpty) {
      return const Center(
        child: Text('No alerts in this category', style: TextStyle(color: Colors.grey)),
      );
    }

    // Sort latest first
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final a = alerts[index];
        
        // Priority Based Styling
        Color priorityColor = Colors.grey;
        
        if (a.priority == 'CRITICAL' || a.severity == 'DANGER' || a.severity == 'CRITICAL') {
          priorityColor = Colors.red;
        } else if (a.priority == 'WARNING' || a.severity == 'WARNING') {
          priorityColor = Colors.orange;
        } else {
          priorityColor = const Color(0xFF00BFFF);
        }

        // Category Based Icons
        IconData categoryIcon = Icons.notifications;
        if (a.alertType == 'TREND') categoryIcon = Icons.trending_up;
        if (a.alertType == 'PREDICTIVE') categoryIcon = Icons.auto_graph;
        if (a.alertType == 'SYSTEM') categoryIcon = Icons.settings_input_component;
        if (a.alertType == 'THRESHOLD') categoryIcon = Icons.shutter_speed;

        // HH:MM 24-hour format
        final hour = a.timestamp.hour.toString().padLeft(2, '0');
        final minute = a.timestamp.minute.toString().padLeft(2, '0');
        final timeString = "$hour:$minute";

        String pondName = a.pondId;
        if (pondsAsync.hasValue) {
          final p = pondsAsync.value!.where((x) => x.id == a.pondId).firstOrNull;
          if (p != null) pondName = p.pondName;
        }

        return GestureDetector(
          onTap: () async {
            if (!a.isRead) {
              final token = ref.read(authStateProvider)?.accessToken ?? '';
              await ref.read(alertServiceProvider).markAsRead(token, a.alertId);
              ref.invalidate(alertsStreamProvider(widget.pondId));
            }
            if (context.mounted) {
              context.push('/user/alert-report/${a.alertId}');
            }
          },
          child: Opacity(
            opacity: a.isRead ? 0.7 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF112236),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: a.isRead ? Colors.transparent : priorityColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 6, color: priorityColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(categoryIcon, color: priorityColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    a.alertType,
                                    style: TextStyle(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                a.alertMessage,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: a.isRead ? Colors.white70 : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(pondName, style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${a.paramName.replaceAll('_', ' ').toUpperCase()}: ${a.getFormattedValue()}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
