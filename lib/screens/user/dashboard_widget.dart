import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sensor_service.dart';
import '../../utils/sensor_formatter.dart';
import 'widgets/status_cards.dart';

class DashboardWidget extends ConsumerWidget {
  final String pondId;
  final String pondName;
  /// If false, the pond has no ESP32 device linked → display zeroed values
  /// with a "No device connected" notice instead of live sensor data.
  final bool isHardwareLinked;

  const DashboardWidget({
    super.key,
    required this.pondId,
    required this.pondName,
    this.isHardwareLinked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveDataAsync = ref.watch(liveSensorProvider(pondId));

    return liveDataAsync.when(
      data: (data) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pond banner
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f?auto=format&crop=entropy&q=80&w=400'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('POND', style: TextStyle(color: Color(0xFF00BFFF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text(pondName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // "No device connected" badge
                    if (!isHardwareLinked)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sensors_off, color: Colors.white54, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'No device connected',
                                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // "No device" info banner when no hardware is linked
              if (!isHardwareLinked)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white38, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No ESP32 device is linked to this pond. All sensor values are reported as 0.',
                          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              const Text('REAL-TIME SENSORS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sensorCard('Temperature', SensorFormatter.formatValue('Temperature', data.temperature), Icons.thermostat, Colors.cyan)),
                  const SizedBox(width: 12),
                  Expanded(child: _sensorCard('pH Level', SensorFormatter.formatValue('pH', data.ph), Icons.science, Colors.cyan)),
                ],
              ),
              const SizedBox(height: 12),
              _sensorCard('TURBIDITY', SensorFormatter.formatValue('Turbidity', data.turbidity), Icons.water_drop, Colors.cyan, fullWidth: true, showSparkline: true),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WaterLevelCard(
                      waterLevel: data.waterLevel.toInt(),
                      waterLevelStr: data.waterLevelStr ?? (data.waterLevel < 50 ? 'LOW' : 'NORMAL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DayNightCard(
                      isDay: data.day == true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  const Text('PREDICTIVE RISK ANALYSIS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(width: 8),
                  if (data.predictionSource == 'ml_on_read')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                      ),
                      child: const Text('HISTORY SNAPSHOT', style: TextStyle(color: Colors.blueGrey, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              _riskRow(
                'Dissolved Oxygen (DO)',
                '${SensorFormatter.formatValue('DO', data.doLevel)} mg/L • ${data.doStatus ?? _getDOStatusLabel(data.doLevel)}',
                data.doStatus ?? _getZone('do', data.doLevel),
                _getZoneColor('do', data.doLevel, data.doStatus),
                Icons.air
              ),
              _riskRow(
                'Ammonia (NH3)',
                '${SensorFormatter.formatValue('NH3', data.ammoniaLevel)} mg/L • ${data.ammoniaStatus ?? _getAmmoniaStatusLabel(data.ammoniaLevel)}',
                data.ammoniaStatus ?? _getZone('ammonia', data.ammoniaLevel),
                _getZoneColor('ammonia', data.ammoniaLevel, data.ammoniaStatus),
                Icons.opacity
              ),
              _riskRow(
                'Carbon Dioxide (CO2)',
                '${SensorFormatter.formatValue('CO2', data.co2Level)} mg/L • ${_getCO2StatusLabel(data.co2Level)}',
                _getZone('co2', data.co2Level),
                _getZoneColor('co2', data.co2Level, null),
                Icons.cloud
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF))),
      error: (e, st) {
        debugPrint('Dashboard Sensor Error: $e');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Sensor Data unavailable: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color, {bool fullWidth = false, bool showSparkline = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF112236), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (showSparkline) const Icon(Icons.show_chart, color: Colors.cyan, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _riskRow(String label, String value, String status, Color statusColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF112236), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- Dynamic Threshold Helpers ---

  String _getZone(String param, double? val) {
    if (val == null || val <= 0) return 'SAFE';
    if (param == 'do') {
      if (val >= 5.0) return 'SAFE';
      if (val >= 3.0) return 'WARNING';
      return 'DANGER';
    } else if (param == 'ammonia') {
      if (val < 0.02) return 'SAFE';
      if (val <= 0.05) return 'WARNING';
      return 'DANGER';
    } else { // co2
      if (val >= 2.0 && val <= 10.0) return 'SAFE';
      if (val > 10.0 || val < 2.0) return 'WARNING';
      return 'DANGER';
    }
  }

  Color _getZoneColor(String param, double? val, String? status) {
    final zone = status ?? _getZone(param, val);
    if (zone == 'SAFE') return Colors.green;
    if (zone == 'WARNING') return Colors.orange;
    return Colors.red;
  }

  String _getDOStatusLabel(double? val) {
    if (val == null) return 'No Data';
    if (val >= 5.0) return 'Optimal';
    if (val >= 3.5) return 'Fair';
    if (val > 0.0) return 'Critical';
    return 'Low/Offline'; 
  }

  String _getAmmoniaStatusLabel(double? val) {
    if (val == null) return 'No Data';
    if (val < 0.02) return 'Stable';
    if (val <= 0.06) return 'Rising';
    return 'Toxic';
  }

  String _getCO2StatusLabel(double? val) {
    if (val == null) return 'No Data';
    if (val >= 2.0 && val <= 8.0) return 'Stable';
    if (val > 10.0) return 'High';
    if (val < 2.0) return 'Low'; 
    return 'Abnormal';
  }
}
