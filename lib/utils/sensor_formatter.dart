class SensorFormatter {
  static String formatValue(String param, double? value) {
    if (value == null) return '--';
    final name = param.toUpperCase();
    
    if (name.contains('TEMPERATURE') || name.contains('TURBIDITY')) {
      return value.round().toString();
    } else if (name.contains('PH')) {
      return value.toStringAsFixed(1);
    } else if (name.contains('AMMONIA') || name.contains('NH3') || 
               name.contains('DO') || name.contains('DISSOLVED OXYGEN') || 
               name.contains('CO2') || name.contains('CARBON DIOXIDE')) {
      return value.toStringAsFixed(2);
    }
    
    return value.toStringAsFixed(2);
  }

  static String getUnit(String param) {
    final p = param.toUpperCase();
    if (p.contains('TEMP')) return '°C';
    if (p.contains('TURBIDITY')) return 'NTU';
    if (p.contains('AMMONIA') || p.contains('NH3') || p.contains('DO') || p.contains('CO2')) return 'mg/L';
    if (p.contains('PH')) return '';
    return '';
  }
}
