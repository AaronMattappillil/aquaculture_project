import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pond_model.dart';
import '../../services/pond_service.dart';
import '../../app.dart';

class PondSettingsScreen extends ConsumerStatefulWidget {
  final String pondId;
  const PondSettingsScreen({super.key, required this.pondId});

  @override
  ConsumerState<PondSettingsScreen> createState() => _PondSettingsScreenState();
}

class _PondSettingsScreenState extends ConsumerState<PondSettingsScreen> {
  PondModel? _pond;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPond();
  }

  Future<void> _loadPond() async {
    try {
      if (widget.pondId.isEmpty) {
        throw Exception('Pond ID is missing');
      }
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final pond = await ref.read(pondServiceProvider).getPondById(token, widget.pondId);
      if (mounted) {
        setState(() {
          _pond = pond;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Settings screen error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePond(Map<String, dynamic> data) async {
    try {
      final token = ref.read(authStateProvider)?.accessToken ?? '';
      final updatedPond = await ref.read(pondServiceProvider).updatePond(token, widget.pondId, data);
      if (mounted) {
        setState(() {
          _pond = updatedPond;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showNameEditDialog() {
    final controller = TextEditingController(text: _pond?.pondName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pond Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Pond Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updatePond({'name': controller.text});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTempRangeDialog() {
    final minController = TextEditingController(text: _pond?.temperatureMin.toString());
    final maxController = TextEditingController(text: _pond?.temperatureMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Temperature Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                decoration: const InputDecoration(labelText: 'Min Temperature (°C)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              TextFormField(
                controller: maxController,
                decoration: const InputDecoration(labelText: 'Max Temperature (°C)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final max = double.tryParse(v ?? '');
                  final min = double.tryParse(minController.text);
                  if (max == null) return 'Enter a valid number';
                  if (min != null && max <= min) return 'Max must be greater than min';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _updatePond({
                  'temp_min': double.parse(minController.text),
                  'temp_max': double.parse(maxController.text),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPhRangeDialog() {
    final minController = TextEditingController(text: _pond?.phMin.toString());
    final maxController = TextEditingController(text: _pond?.phMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit pH Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                decoration: const InputDecoration(labelText: 'Min pH'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null) return 'Enter a valid number';
                  if (val < 0 || val > 14) return 'pH must be between 0 and 14';
                  return null;
                },
              ),
              TextFormField(
                controller: maxController,
                decoration: const InputDecoration(labelText: 'Max pH'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final max = double.tryParse(v ?? '');
                  final min = double.tryParse(minController.text);
                  if (max == null) return 'Enter a valid number';
                  if (max < 0 || max > 14) return 'pH must be between 0 and 14';
                  if (min != null && max <= min) return 'Max must be greater than min';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _updatePond({
                  'ph_min': double.parse(minController.text),
                  'ph_max': double.parse(maxController.text),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTurbidityDialog() {
    final minController = TextEditingController(text: _pond?.turbidityMin.toString());
    final maxController = TextEditingController(text: _pond?.turbidityMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Turbidity Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                decoration: const InputDecoration(labelText: 'Min Turbidity (NTU)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              TextFormField(
                controller: maxController,
                decoration: const InputDecoration(labelText: 'Max Turbidity (NTU)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final max = double.tryParse(v ?? '');
                  final min = double.tryParse(minController.text);
                  if (max == null) return 'Enter a valid number';
                  if (min != null && max <= min) return 'Max must be greater than min';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _updatePond({
                  'turbidity_min': double.parse(minController.text),
                  'turbidity_max': double.parse(maxController.text),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    final pond = _pond!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pond Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('GENERAL INFO', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _settingItem(Icons.edit, 'Pond Name', pond.pondName, _showNameEditDialog),
          _settingItem(Icons.location_on, 'Location', pond.location, null),
          _settingItem(Icons.straighten, 'Dimensions', '${pond.lengthM} x ${pond.widthM} x ${pond.heightM} meters', null),
          
          const SizedBox(height: 32),
          const Text('ALERTS & THRESHOLDS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _settingItem(Icons.thermostat, 'Temperature Range', '${pond.temperatureMin}°C - ${pond.temperatureMax}°C', _showTempRangeDialog),
          _settingItem(Icons.science, 'pH Range', '${pond.phMin} - ${pond.phMax}', _showPhRangeDialog),
          _settingItem(Icons.water, 'Turbidity Range', '${pond.turbidityMin} NTU - ${pond.turbidityMax} NTU', _showTurbidityDialog),
          
          const SizedBox(height: 32),
          const Text('NOTIFICATION PREFERENCES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts on your mobile device'),
            value: pond.pushNotifications,
            activeThumbColor: const Color(0xFF0E6E8A),
            onChanged: (v) => _updatePond({'push_notifications': v}),
          ),
          SwitchListTile(
            title: const Text('Email Alerts'),
            subtitle: const Text('Receive reports via email'),
            value: pond.emailAlerts,
            activeThumbColor: const Color(0xFF0E6E8A),
            onChanged: (v) => _updatePond({'email_alerts': v}),
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, String value, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0E6E8A)),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(color: Colors.grey)),
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 16, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}
