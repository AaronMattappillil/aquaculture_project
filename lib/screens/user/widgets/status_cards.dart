import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WaterLevelCard extends StatelessWidget {
  final int waterLevel;
  final String? waterLevelStr;

  const WaterLevelCard({super.key, required this.waterLevel, this.waterLevelStr});

  @override
  Widget build(BuildContext context) {
    // Backend provided status takes precedence (LOW, NORMAL)
    final bool isLow = (waterLevelStr?.toUpperCase() == "LOW") || (waterLevelStr == null && waterLevel <= 30);
    final String statusText = waterLevelStr ?? (isLow ? "Low" : "Normal");
    final Color statusColor = isLow ? warningColor : safeColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.water, color: statusColor, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Water Level',
            style: TextStyle(
              color: secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DayNightCard extends StatelessWidget {
  final bool isDay;

  const DayNightCard({super.key, required this.isDay});

  @override
  Widget build(BuildContext context) {
    final String statusText = isDay ? "Day" : "Night";
    final IconData statusIcon = isDay ? Icons.wb_sunny : Icons.nightlight_round;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(statusIcon, color: accentTeal, size: 24),
              Icon(Icons.brightness_auto, color: secondaryText.withValues(alpha: 0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Environment',
            style: TextStyle(
              color: secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
