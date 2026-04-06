import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/pond_model.dart';
import '../../services/pond_service.dart';
import 'package:aquasense/services/alert_service.dart';
import '../../app.dart';
import 'data_visualization_screen.dart';
import 'dashboard_widget.dart';
import 'support_screen.dart';
import 'alerts_screen.dart';
import 'ponds_list_screen.dart';

class PondShellScreen extends ConsumerStatefulWidget {
  final String pondId;
  const PondShellScreen({super.key, required this.pondId});

  @override
  ConsumerState<PondShellScreen> createState() => _PondShellScreenState();
}

class _PondShellScreenState extends ConsumerState<PondShellScreen> {
  int _selectedIndex = 0;
  PondModel? _pond;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPond();
  }

  Future<void> _loadPond() async {
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final pond = await ref.read(pondServiceProvider).getPondById(token, widget.pondId);
      if (mounted) {
        setState(() {
          _pond = pond;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final updatedPond = await ref.read(pondServiceProvider).updatePond(token, widget.pondId, {'status': newStatus});
      if (mounted) {
        setState(() {
          _pond = updatedPond;
        });
        // Invalidate ponds list to reflect changes
        ref.invalidate(activePondStatusProvider);
        ref.invalidate(pondsFutureProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pond = _pond;
    final pondName = pond?.pondName ?? 'Pond ${widget.pondId}';
    final currentStatus = pond?.status.toUpperCase() ?? 'ACTIVE';

    Color statusColor;
    switch (currentStatus) {
      case 'ACTIVE':
        statusColor = Colors.green;
        break;
      case 'HARVEST':
        statusColor = Colors.orange;
        break;
      case 'INACTIVE':
      default:
        statusColor = Colors.grey;
    }



    Widget buildInactivePondView() {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "This pond is disabled.\nPlease contact admin to activate this pond.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, height: 1.5, fontSize: 16),
          ),
        ),
      );
    }

    const cyanColor = Color(0xFF00BFFF);
    const darkBg = Color(0xFF0B0E11);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/user/ponds'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pondName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            if (currentStatus != 'INACTIVE')
              PopupMenuButton<String>(
                onSelected: _updateStatus,
                offset: const Offset(0, 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'ACTIVE', child: Text('Active')),
                  const PopupMenuItem(value: 'HARVEST', child: Text('Harvest')),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('LIVE STATUS: $currentStatus', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE STATUS: $currentStatus', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF112236),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF0E6E8A)),
                onPressed: () async {
                  await context.push('/user/settings/${widget.pondId}');
                  _loadPond(); // Reload on return in case name changed
                },
              ),
            ),
          ),
        ],
      ),
      // isActive is sourced from the MongoDB pond record (loaded via REST API).
      // No Firestore stream needed here.
      body: Builder(builder: (context) {
          final bool hasAccess = currentStatus != 'INACTIVE';
          final List<Widget> pages = [
            hasAccess ? DashboardWidget(pondId: widget.pondId, pondName: pondName, isHardwareLinked: pond?.isHardwareLinked ?? false) : buildInactivePondView(), // DASHBOARD
            hasAccess ? DataVisualizationWidget(pondId: widget.pondId) : buildInactivePondView(),             // DATA
            hasAccess ? AlertsWidget(pondId: widget.pondId) : buildInactivePondView(),                        // ALERTS
            SupportWidget(pondId: widget.pondId),                                      // SUPPORT
          ];
          return IndexedStack(
            index: _selectedIndex,
            children: pages,
          );
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF112236),
        selectedItemColor: cyanColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'DASHBOARD',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.layers_outlined),
            label: 'DATA ANALYTICS',
          ),
          BottomNavigationBarItem(
            icon: ref.watch(alertsStreamProvider(widget.pondId)).when(
              data: (alerts) {
                final hasUnread = alerts.any((a) => !a.isRead);
                return Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                          constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                        ),
                      )
                  ],
                );
              },
              loading: () => const Icon(Icons.notifications_outlined),
              error: (_, __) => const Icon(Icons.notifications_outlined),
            ),
            label: 'ALERTS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'SUPPORT',
          ),
        ],
      ),
    );
  }
}
