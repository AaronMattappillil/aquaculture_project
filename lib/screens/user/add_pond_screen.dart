// Version: 1.0.1 - AGENT_SYNC_RETRY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/pond_service.dart';
import '../../services/fish_species_service.dart';
import '../../models/fish_species_model.dart';
import '../../app.dart';
import 'ponds_list_screen.dart';

class AddPondScreen extends ConsumerStatefulWidget {
  const AddPondScreen({super.key});

  @override
  ConsumerState<AddPondScreen> createState() => _AddPondScreenState();
}

class _AddPondScreenState extends ConsumerState<AddPondScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _fishUnitsController = TextEditingController(text: '0');
  final _tempMinController = TextEditingController(text: '22.0');
  final _tempMaxController = TextEditingController(text: '30.0');
  final _phMinController = TextEditingController(text: '6.5');
  final _phMaxController = TextEditingController(text: '8.5');
  final _turbidityController = TextEditingController(text: '10.0');

  FishSpeciesModel? _selectedSpecies;
  bool _isLoading = false;
  double _volume = 0.0;
  bool _thresholdsCustomized = false;

  @override
  void initState() {
    super.initState();
    _lengthController.addListener(_calculateVolume);
    _widthController.addListener(_calculateVolume);
    _heightController.addListener(_calculateVolume);
  }

  void _calculateVolume() {
    final length = double.tryParse(_lengthController.text) ?? 0.0;
    final width = double.tryParse(_widthController.text) ?? 0.0;
    final height = double.tryParse(_heightController.text) ?? 0.0;
    setState(() => _volume = length * width * height);
  }

  void _applySpeciesDefaults(FishSpeciesModel species) {
    setState(() {
      _tempMinController.text = species.temperatureMin.toString();
      _tempMaxController.text = species.temperatureMax.toString();
      _phMinController.text = species.phMin.toString();
      _phMaxController.text = species.phMax.toString();
      _turbidityController.text = species.turbidity.toString();
      _thresholdsCustomized = false;
    });
  }

  Future<void> _onSpeciesChanged(FishSpeciesModel? newSpecies) async {
    if (newSpecies == null) return;
    if (_thresholdsCustomized) {
      final reset = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF112236),
          title: const Text('Reset Thresholds?', style: TextStyle(color: Colors.white)),
          content: Text('Reset thresholds to recommended values for ${newSpecies.name}?', style: const TextStyle(color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Custom')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Color(0xFF0E6E8A)))),
          ],
        ),
      );
      setState(() => _selectedSpecies = newSpecies);
      if (reset == true) _applySpeciesDefaults(newSpecies);
    } else {
      setState(() => _selectedSpecies = newSpecies);
      _applySpeciesDefaults(newSpecies);
    }
  }

  Future<void> _showAddSpeciesDialog() async {
    final nameCtrl = TextEditingController();
    final tMinCtrl = TextEditingController(text: '22.0');
    final tMaxCtrl = TextEditingController(text: '30.0');
    final phMinCtrl = TextEditingController(text: '6.5');
    final phMaxCtrl = TextEditingController(text: '8.5');
    final turbCtrl = TextEditingController(text: '10.0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF112236),
        title: const Text('Add Custom Fish Species', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Species Name', 'e.g. Salmon', isText: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dialogField(tMinCtrl, 'Temp Min °C', '22')),
                const SizedBox(width: 8),
                Expanded(child: _dialogField(tMaxCtrl, 'Temp Max °C', '30')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dialogField(phMinCtrl, 'pH Min', '6.5')),
                const SizedBox(width: 8),
                Expanded(child: _dialogField(phMaxCtrl, 'pH Max', '8.5')),
              ]),
              const SizedBox(height: 12),
              _dialogField(turbCtrl, 'Turbidity (NTU)', '10'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E8A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;

      final newSpecies = FishSpeciesModel(
        id: '',
        name: name,
        isCustom: true,
        temperatureMin: double.tryParse(tMinCtrl.text) ?? 22.0,
        temperatureMax: double.tryParse(tMaxCtrl.text) ?? 30.0,
        phMin: double.tryParse(phMinCtrl.text) ?? 6.5,
        phMax: double.tryParse(phMaxCtrl.text) ?? 8.5,
        turbidity: double.tryParse(turbCtrl.text) ?? 10.0,
      );

      try {
        await ref.read(fishSpeciesServiceProvider).createFishSpecies(newSpecies);
        ref.invalidate(fishSpeciesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Species "$name" added successfully!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving species: $e')));
        }
      }
    }
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {bool isText = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isText ? TextInputType.text : TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black26,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Future<void> _createPond() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a pond name')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider);
      if (user == null) throw Exception('Not authenticated');

      final pondData = {
        'name': _nameController.text,
        'location': _locationController.text,
        'length_m': double.tryParse(_lengthController.text) ?? 10.0,
        'width_m': double.tryParse(_widthController.text) ?? 5.0,
        'height_m': double.tryParse(_heightController.text) ?? 2.0,
        'volume_m3': _volume,
        'fish_species': _selectedSpecies?.name ?? 'Unknown',
        'fish_units': int.tryParse(_fishUnitsController.text) ?? 0,
        'temperature_min': double.tryParse(_tempMinController.text) ?? 22.0,
        'temperature_max': double.tryParse(_tempMaxController.text) ?? 30.0,
        'ph_min': double.tryParse(_phMinController.text) ?? 6.5,
        'ph_max': double.tryParse(_phMaxController.text) ?? 8.5,
        'turbidity_min': 0.0,
        'turbidity_max': double.tryParse(_turbidityController.text) ?? 40.0,
        'status': 'INACTIVE',
      };

      await ref.read(pondServiceProvider).createPond(user.accessToken, pondData);
      ref.invalidate(pondsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pond added successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _lengthController.removeListener(_calculateVolume);
    _widthController.removeListener(_calculateVolume);
    _heightController.removeListener(_calculateVolume);
    _nameController.dispose();
    _locationController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _fishUnitsController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _phMinController.dispose();
    _phMaxController.dispose();
    _turbidityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(fishSpeciesProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Add New Pond')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card('Basic Info', [
                _tf(_nameController, 'Pond Name', 'e.g. North Pond'),
                const SizedBox(height: 16),
                _tf(_locationController, 'Location', 'e.g. Site A'),
            ]),
            const SizedBox(height: 16),
            _card('Dimensions', [
              Row(
                children: [
                  Expanded(child: _tf(_lengthController, 'Length (m)', '10.0', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _tf(_widthController, 'Width (m)', '5.0', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _tf(_heightController, 'Depth/Height (m)', '2.0', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E6E8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0E6E8A).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calculated Volume:', style: TextStyle(color: Colors.grey)),
                    Text(
                      _volume > 0 ? '${_volume.toStringAsFixed(2)} m³' : 'Enter dimensions',
                      style: const TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Fish Information Card — loads from API
            _card('Fish Information', [
              speciesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed to load species: $e', style: const TextStyle(color: Colors.redAccent)),
                data: (speciesList) {
                  // Ensure selected species is valid
                  if (_selectedSpecies == null && speciesList.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _onSpeciesChanged(speciesList.first);
                    });
                  }
                  final validSelected = speciesList.where((s) => s.id == _selectedSpecies?.id).firstOrNull ?? 
                                       (speciesList.isEmpty ? null : speciesList.first);

                  return DropdownButtonFormField<FishSpeciesModel>(
                    initialValue: validSelected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Fish Type / Species',
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...speciesList.map((s) => DropdownMenuItem<FishSpeciesModel>(
                            value: s,
                            child: Text(s.name),
                          )),
                      DropdownMenuItem<FishSpeciesModel>(
                        value: FishSpeciesModel.addNew,
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0E6E8A)),
                            SizedBox(width: 6),
                            Text('Add Custom Species...', style: TextStyle(color: Color(0xFF0E6E8A), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (s) {
                      if (s == FishSpeciesModel.addNew) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showAddSpeciesDialog();
                        });
                      } else if (s != null) {
                        _onSpeciesChanged(s);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _selectedSpecies != null
                        ? 'Thresholds auto-filled for ${_selectedSpecies!.name}'
                        : 'Select a species to auto-fill thresholds',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _tf(_fishUnitsController, 'Fish Units', '0', keyboardType: TextInputType.number),
            ]),

            const SizedBox(height: 16),

            // Thresholds card — auto-filled from species, editable
            _card('Thresholds', [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E6E8A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0E6E8A).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0E6E8A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedSpecies != null
                            ? 'Recommended values for ${_selectedSpecies!.name}. You can edit them.'
                            : 'Select a species to auto-fill thresholds.',
                        style: const TextStyle(color: Color(0xFF0E6E8A), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: _tf(_tempMinController, 'Temp Min (°C)', '22.0', keyboardType: TextInputType.number, onChanged: (_) => _thresholdsCustomized = true)),
                  const SizedBox(width: 16),
                  Expanded(child: _tf(_tempMaxController, 'Temp Max (°C)', '30.0', keyboardType: TextInputType.number, onChanged: (_) => _thresholdsCustomized = true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _tf(_phMinController, 'pH Min', '6.5', keyboardType: TextInputType.number, onChanged: (_) => _thresholdsCustomized = true)),
                  const SizedBox(width: 16),
                  Expanded(child: _tf(_phMaxController, 'pH Max', '8.5', keyboardType: TextInputType.number, onChanged: (_) => _thresholdsCustomized = true)),
                ],
              ),
              const SizedBox(height: 16),
              _tf(_turbidityController, 'Turbidity (NTU)', '10.0', keyboardType: TextInputType.number, onChanged: (_) => _thresholdsCustomized = true),
            ]),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E8A), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _createPond,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Pond', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Agree to Terms & Services before adding.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF112236),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }

  Widget _tf(TextEditingController controller, String label, String hint,
      {TextInputType? keyboardType, void Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.black12,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
