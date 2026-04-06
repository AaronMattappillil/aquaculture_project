// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/support_ticket_service.dart';
import '../../models/support_ticket_model.dart';
import '../../app.dart';

final supportTicketsProvider = FutureProvider<List<SupportTicketModel>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return const <SupportTicketModel>[];
  final token = user.accessToken;
  final userId = user.id; // Using actual user ID if available, though it might be used for mock
  return await ref.watch(supportTicketServiceProvider).getUserTickets(token, userId: userId);
});

class SupportScreen extends StatelessWidget {
  final String? pondId;
  const SupportScreen({super.key, this.pondId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Support')),
      body: SupportWidget(pondId: pondId),
    );
  }
}

class SupportWidget extends ConsumerStatefulWidget {
  final String? pondId;
  const SupportWidget({super.key, this.pondId});

  @override
  ConsumerState<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends ConsumerState<SupportWidget> {
  final _subjectCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_msgCtrl.text.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authStateProvider);
      final token = user?.accessToken ?? '';
      await ref.read(supportTicketServiceProvider).createTicket(
        token: token, 
        category: _selectedCategory,
        subject: _subjectCtrl.text.isEmpty ? 'Support Request: $_selectedCategory' : _subjectCtrl.text, 
        description: _msgCtrl.text,
        pondId: widget.pondId, 
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Care request created successfully')));
        _msgCtrl.clear();
        _subjectCtrl.clear();
        ref.invalidate(supportTicketsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Submit a Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0E6E8A))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', filled: true, fillColor: Color(0xFF112236), border: OutlineInputBorder()),
              items: ['Technical Issue','Billing','Customer Care','General','Sensor Calibration','Emergency'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'General'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject (Optional)', filled: true, fillColor: Color(0xFF112236), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message', filled: true, fillColor: Color(0xFF112236), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E8A), padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'Submit', 
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
            
            const SizedBox(height: 32),
            const Text('Support History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0E6E8A))),
            const SizedBox(height: 16),
            
            ticketsAsync.when(
              data: (tickets) {
                final currentPondId = widget.pondId;
                
                // 1. Hardcoded Constraint: If not the connected pond, show blank
                if (currentPondId != '69cec3ae6fca89e082227165') {
                  return const Center(child: Text('No support history found.', style: TextStyle(color: Colors.grey)));
                }

                // 2. Category Constraint: Emergency and Sensor Calibration are siloed
                final filtered = tickets.where((t) {
                  final category = t.category.toLowerCase();
                  if (category == 'emergency' || category == 'sensor calibration') {
                    return t.pondId == currentPondId;
                  }
                  return true; // General categories are visible across ponds
                }).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('No support history found.', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return Card(
                      color: const Color(0xFF112236),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => context.push('/user/ticket/${t.ticketId}'),
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(t.category, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.status == 'resolved' ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(t.status.toUpperCase(), style: TextStyle(fontSize: 10, color: t.status == 'resolved' ? Colors.green : Colors.red)),
                            )
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
