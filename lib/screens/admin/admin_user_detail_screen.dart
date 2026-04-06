// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart';
import '../../models/pond_model.dart';
import '../../services/admin_service.dart';
import '../../services/pond_service.dart';
import '../../app.dart';
import 'admin_users_screen.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  AdminUserDetail? _profile;
  bool _isLoading = true;
  String? _error;

  // Track optimistic status state per pond (pondId → status)
  final Map<String, String> _pondStatusOverrides = {};
  final Map<String, bool> _pondTogglingInProgress = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final profile = await ref.read(adminServiceProvider).getUserDetail(token, widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _pondStatusOverrides.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePondActive(AdminUserDetailPond pond, bool newVal) async {
    final pondId = pond.id;
    if (_pondTogglingInProgress[pondId] == true) return;

    final newStatus = newVal ? 'ACTIVE' : 'INACTIVE';

    setState(() {
      _pondStatusOverrides[pondId] = newStatus;
      _pondTogglingInProgress[pondId] = true;
    });

    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      await ref.read(pondServiceProvider).updatePond(
        token,
        pondId,
        {'status': newStatus},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _pondStatusOverrides[pondId] = newVal ? 'INACTIVE' : 'ACTIVE');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pond status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pondTogglingInProgress[pondId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    final isAdminSelf = ref.read(authStateProvider)?.id == p.user.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('User Detail'),
        actions: [
          if (!isAdminSelf) ...[
            IconButton(
              icon: const Icon(Icons.block, color: Colors.orange),
              onPressed: () => _showBanConfirm(context, p.user),
              tooltip: p.user.status == 'BANNED' ? 'Unban User' : 'Ban User',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _showDeleteConfirm(context, p.user),
              tooltip: 'Delete User',
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Section
              Card(
                color: const Color(0xFF112236),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF0E6E8A),
                        child: Icon(Icons.person, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text('${p.user.firstName} ${p.user.lastName}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(p.user.email, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(p.user.phone, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.user.status == 'BANNED'
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.user.status,
                          style: TextStyle(
                            color: p.user.status == 'BANNED' ? Colors.red : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Ponds Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ponds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0E6E8A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E6E8A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Total: ${p.ponds.count}',
                        style: const TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (p.ponds.items.isEmpty)
                const Center(child: Text('No ponds registered', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: p.ponds.items.length,
                  itemBuilder: (context, index) {
                    final pond = p.ponds.items[index];
                    final status = _pondStatusOverrides[pond.id] ?? pond.status;
                    final isActive = status == 'ACTIVE';
                    final isToggling = _pondTogglingInProgress[pond.id] == true;

                    return Card(
                      color: const Color(0xFF112236),
                      child: ListTile(
                        onTap: () => context.push('/admin/pond/${pond.id}'),
                        title: Text(pond.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${pond.fishSpecies} • ${pond.fishUnits} units'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isToggling
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : Switch(
                                    value: isActive,
                                    activeThumbColor: const Color(0xFF0E6E8A),
                                    onChanged: (val) => _togglePondActive(pond, val),
                                  ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Tickets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Support Tickets',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0E6E8A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E6E8A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Total: ${p.tickets.count}',
                        style: const TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (p.tickets.items.isEmpty)
                const Center(child: Text('No support tickets', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: p.tickets.items.length,
                  itemBuilder: (context, index) {
                    final t = p.tickets.items[index];
                    final isOpen = t.status.toUpperCase() == 'OPEN' || t.status.toUpperCase() == 'IN_PROGRESS';
                    return Card(
                      color: const Color(0xFF112236),
                      child: ListTile(
                        onTap: () => context.push('/admin/complaint/${t.id}'),
                        title: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${t.category} • ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.status,
                            style: TextStyle(color: isOpen ? Colors.orange : Colors.green, fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _showDeleteConfirm(BuildContext context, AdminUserDetailUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final token = ref.read(authStateProvider)?.accessToken ?? '';
        await ref.read(adminServiceProvider).deleteUser(token, user.id);
        ref.invalidate(adminUsersProvider);
        ref.invalidate(adminDashboardProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
        context.pop();
      } catch (e) {
        if (!context.mounted) return;
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _showBanConfirm(BuildContext context, AdminUserDetailUser user) async {
    final isBanning = user.status != 'BANNED';
    final actionText = isBanning ? 'Ban' : 'Unban';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText User?'),
        content: Text('Are you sure you want to $actionText ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isBanning ? Colors.orange : Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final token = ref.read(authStateProvider)?.accessToken ?? '';
        final newStatus = isBanning ? 'BANNED' : 'ACTIVE';
        await ref.read(adminServiceProvider).updateUserStatus(token, user.id, newStatus);
        ref.invalidate(adminUsersProvider);
        ref.invalidate(adminDashboardProvider);
        _loadData(); 
      } catch (e) {
        if (!context.mounted) return;
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }
}
