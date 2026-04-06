// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart';
import '../../models/support_ticket_model.dart';
import '../../services/admin_service.dart';
import '../../services/support_ticket_service.dart';
import '../../app.dart';
import 'admin_dashboard_screen.dart';

final adminUsersProvider = FutureProvider<List<AdminUserSummary>>((ref) async {
  final token = ref.read(authStateProvider)?.accessToken ?? '';
  return ref.read(adminServiceProvider).getAdminUsers(token);
});

final adminTicketsProvider = FutureProvider.family<List<SupportTicketModel>, String?>((ref, status) async {
  final token = ref.read(authStateProvider)?.accessToken ?? '';
  return ref.read(supportTicketServiceProvider).getUserTickets(token, status: status);
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  int _currentIndex = 0;
  String query = '';

  void _logout() {
    ref.read(authStateProvider.notifier).state = null;
    // Redirect happens automatically via refreshListenable in GoRouter
    // but we can also do it explicitly to be safe
    // context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('AquaSense'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0E6E8A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF112236),
        selectedItemColor: const Color(0xFF0E6E8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Customer Care'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return _UsersList(query: query, onQueryChanged: (v) => setState(() => query = v));
      case 2:
        return const _TicketsList();
      default:
        return const AdminDashboardScreen();
    }
  }
}

class _UsersList extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;

  const _UsersList({required this.query, required this.onQueryChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search user...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF112236),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                String normalize(String text) {
                  return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
                }
                final normalizedQuery = normalize(query);

                final filtered = users.where((u) {
                  if (normalizedQuery.isEmpty) return true;
                  final fullName = normalize('${u.firstName} ${u.lastName}');
                  final email = normalize(u.email);
                  final username = normalize(u.username);
                  return fullName.contains(normalizedQuery) ||
                         email.contains(normalizedQuery) ||
                         username.contains(normalizedQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return Card(
                      color: const Color(0xFF112236),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => context.push('/admin/user/${u.id}'),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0E6E8A),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('${u.firstName} ${u.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${u.email} • ${u.role}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) {
                return Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red)));
              },
            ),
          )
        ],
      ),
    );
  }
}

class _TicketsList extends ConsumerWidget {
  const _TicketsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // Default to "Open"
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFF0E6E8A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0E6E8A),
            tabs: [
              Tab(child: _TabLabel(label: 'All', status: null)),
              Tab(child: _TabLabel(label: 'Open', status: 'open')),
              Tab(child: _TabLabel(label: 'Resolved', status: 'resolved')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TicketListView(status: null),
                _TicketListView(status: 'open'),
                _TicketListView(status: 'resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends ConsumerWidget {
  final String label;
  final String? status;
  const _TabLabel({required this.label, this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(adminTicketsProvider(status));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        ticketsAsync.when(
          data: (tickets) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Text('${tickets.length}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}

class _TicketListView extends ConsumerWidget {
  final String? status;
  const _TicketListView({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(adminTicketsProvider(status));

    return ticketsAsync.when(
      data: (tickets) {
        final filtered = tickets; // No more category filtering

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No ${status ?? "matching"} items found',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminTicketsProvider(status).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final t = filtered[index];
              final isOpen = t.status == 'open';
              
              return Opacity(
                opacity: isOpen ? 1.0 : 0.6,
                child: Card(
                  color: const Color(0xFF112236),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => context.push('/admin/complaint/${t.ticketId}'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOpen ? Icons.mail : Icons.mark_email_read,
                        color: isOpen ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.subject, 
                      style: TextStyle(
                        fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
                        color: isOpen ? Colors.white : Colors.white70,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('User: ${t.userEmail.isNotEmpty ? t.userEmail : t.userId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (t.pondId != null)
                          Text('Pond: ${t.pondId}', style: const TextStyle(color: Color(0xFF0E6E8A), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('ID: ${t.ticketId}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isOpen ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            t.status.toUpperCase(),
                            style: TextStyle(color: isOpen ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}
