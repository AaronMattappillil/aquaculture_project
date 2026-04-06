import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/pond_service.dart';
import '../../models/pond_model.dart';
import '../../app.dart';

final activePondStatusProvider = StateProvider<String>((ref) => 'All');

final pondsFutureProvider = FutureProvider<List<PondModel>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null || user.accessToken.isEmpty) {
    throw Exception('User not authenticated');
  }
  final status = ref.watch(activePondStatusProvider);
  return ref.watch(pondServiceProvider).getUserPonds(user.accessToken, status: status);
});

class PondsListScreen extends ConsumerWidget {
  const PondsListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PondModel pond) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF112236),
        title: const Text('Delete Pond', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${pond.pondName}"? This action cannot be undone.', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = ref.read(authStateProvider);
        if (user == null) throw Exception('Not authenticated');

        await ref.read(pondServiceProvider).deletePond(user.accessToken, pond.id);
        ref.invalidate(pondsFutureProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pond "${pond.pondName}" deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final pondsAsync = ref.watch(pondsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.push('/user/profile'),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF112236),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AquaSense', style: TextStyle(fontSize: 16)),
            Text('Monitoring Active', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.push('/user/alerts')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Ponds', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFF112236), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['All', 'Active', 'Inactive', 'Harvest'].map((s) {
                      final isSelected = ref.watch(activePondStatusProvider) == s;
                      return GestureDetector(
                        onTap: () => ref.read(activePondStatusProvider.notifier).state = s,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0E6E8A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            s == 'Harvest' ? 'Harv.' : s,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(pondsFutureProvider.future),
              child: pondsAsync.when(
                data: (ponds) {
                  if (ponds.isEmpty) {
                    final currentStatus = ref.watch(activePondStatusProvider);
                    final isFiltered = currentStatus != 'All';
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            isFiltered ? 'No $currentStatus ponds found.' : 'No ponds yet.',
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          if (!isFiltered)
                            const Text('Tap + to initialize your first pond.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ponds.length,
                    itemBuilder: (context, index) {
                      final p = ponds[index];
                      
                      Color statusColor;
                      switch (p.status.toUpperCase()) {
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

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/user/dashboard/${p.id}'),
                        child: Card(
                        color: const Color(0xFF112236),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(p.status.toUpperCase(), style: TextStyle(
                                      color: statusColor, fontSize: 10, fontWeight: FontWeight.bold
                                    )),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => _confirmDelete(context, ref, p),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(p.pondName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${p.fishSpecies} • ${p.fishUnits} units', style: const TextStyle(color: Colors.grey)),
                              if ((p.estimatedFishCount ?? 0) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Est. fish: ${p.estimatedFishCount}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      );
                  },
                );
              },

              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              )),
            ),
          ),
        ),
      ],
    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0E6E8A),
        onPressed: () => context.push('/user/add-pond'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
