import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/alert_service.dart';
import '../../models/alert_model.dart';
import '../../app.dart';
import 'ponds_list_screen.dart';
import '../../utils/sensor_formatter.dart';
import '../../models/report_model.dart';

class AlertReportScreen extends ConsumerStatefulWidget {
  final String alertId;
  const AlertReportScreen({super.key, required this.alertId});

  @override
  ConsumerState<AlertReportScreen> createState() => _AlertReportScreenState();
}

class _AlertReportScreenState extends ConsumerState<AlertReportScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    // Avoid marking as read if dummy data might reset
    final user = ref.read(authStateProvider);
    if (user == null) return;
    try {
      await ref.read(alertServiceProvider).updateAlert(user.accessToken, widget.alertId, {'is_read': true});
      // Invalidate both the global list and potentially the pond-specific list
      ref.invalidate(alertsStreamProvider(null));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(alertByIdProvider(widget.alertId));
    final reportAsync = ref.watch(reportByAlertIdProvider(widget.alertId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Incident Report'),
      ),
      body: alertAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                Text('Failed to load alert: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        data: (alert) => reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildBody(context, ref, alert, null), // Fallback if report fails
          data: (report) => _buildBody(context, ref, alert, report),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AlertModel alert, ReportModel? report) {
    Color headerColor;
    IconData headerIcon;
    String severityLabel;

    final pondsAsync = ref.watch(pondsFutureProvider);
    String pondName = alert.pondId;
    if (pondsAsync.hasValue) {
      final p = pondsAsync.value!.where((x) => x.id == alert.pondId).firstOrNull;
      if (p != null) pondName = p.pondName;
    }

    final sev = alert.severity.toUpperCase();
    if (sev == 'CRITICAL' || sev == 'DANGER') {
      headerColor = Colors.red.shade900;
      headerIcon = Icons.error;
      severityLabel = 'DANGER ALERT';
    } else if (sev == 'WARNING') {
      headerColor = Colors.orange.shade800;
      headerIcon = Icons.warning;
      severityLabel = 'WARNING ALERT';
    } else {
      headerColor = Colors.green.shade800;
      headerIcon = Icons.check_circle;
      severityLabel = 'SYSTEM NOTICE';
    }

    final formattedTime = '${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year} '
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            color: headerColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(headerIcon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(severityLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(alert.alertMessage, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                  child: Text(alert.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Meta info
                Card(
                  color: const Color(0xFF112236),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _metaRow('Pond', pondName),
                        const Divider(color: Colors.white10),
                        _metaRow('Timestamp', formattedTime),
                        const Divider(color: Colors.white10),
                        _metaRow('Parameter', alert.paramName.toUpperCase()),
                        const Divider(color: Colors.white10),
                        _metaRow('Recorded Value', alert.getFormattedValue()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sensor Snapshot
                const Text('Sensor Snapshot at Alert Time', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _snapCard(alert.paramName.toUpperCase(), alert.getFormattedValue(), headerColor.withValues(alpha: 1.0))),
                    const SizedBox(width: 8),
                    Expanded(child: _snapCard('Alert ID', '#${alert.alertId.substring(0, 6)}...', Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(child: _snapCard('Status', alert.status, alert.status == 'RESOLVED' ? Colors.green : Colors.orange)),
                  ],
                ),

                const SizedBox(height: 24),

                // Analysis
                const Text('Analysis', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF112236),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      report != null && report.trendAnalysis.isNotEmpty
                          ? report.trendAnalysis
                          : '${alert.paramName.toUpperCase()} reached ${SensorFormatter.formatValue(alert.paramName, alert.paramValue)}, which triggered a ${alert.severity == 'CRITICAL' ? 'DANGER' : alert.severity} alert. '
                            'Immediate attention is recommended to prevent harm to your aquaculture stock.',
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Required Actions
                const Text('Recommended Actions', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (report != null && report.recommendations.isNotEmpty)
                  ...report.recommendations.map((r) => _checkItem(r))
                else ...[
                  _checkItem('Inspect the affected pond immediately'),
                  _checkItem('Check and calibrate sensors if needed'),
                  _checkItem('Apply corrective treatment as required'),
                ],

                const SizedBox(height: 32),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFF0E6E8A))),
                  onPressed: () => context.push('/user/support'),
                  child: const Text('Contact Support', style: TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                if (alert.status != 'RESOLVED')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E8A), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      final user = ref.read(authStateProvider);
                      if (user == null) return;
                      await ref.read(alertServiceProvider).updateAlert(user.accessToken, widget.alertId, {'status': 'RESOLVED'});
                      ref.invalidate(alertByIdProvider(widget.alertId));
                      ref.invalidate(alertsStreamProvider(null));
                      // Use the passed alert object instead of trying to access alertAsync
                      ref.invalidate(alertsStreamProvider(alert.pondId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert marked as resolved')));
                      }
                    },
                    child: const Text('Mark as Resolved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _snapCard(String label, String value, Color color) {
    return Card(
      color: const Color(0xFF112236),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _checkItem(String text) {
    return CheckboxListTile(
      value: false,
      onChanged: (v) {},
      title: Text(text),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF0E6E8A),
    );
  }
}
