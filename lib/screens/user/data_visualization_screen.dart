import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_reading_model.dart';

import '../../app.dart';

final historyProvider = FutureProvider.family<List<SensorReadingModel>, String>((ref, pondId) {
  final user = ref.watch(authStateProvider);
  final token = user?.accessToken ?? '';
  return ref.watch(sensorServiceProvider).getHistoricalData(token, pondId);
});

class DataVisualizationScreen extends StatelessWidget {
  final String pondId;
  const DataVisualizationScreen({super.key, required this.pondId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Data Visualization'),
      ),
      body: DataVisualizationWidget(pondId: pondId),
    );
  }
}

class DataVisualizationWidget extends ConsumerStatefulWidget {
  final String pondId;
  const DataVisualizationWidget({super.key, required this.pondId});

  @override
  ConsumerState<DataVisualizationWidget> createState() => _DataVisualizationWidgetState();
}

class _DataVisualizationWidgetState extends ConsumerState<DataVisualizationWidget> {
  String selectedParam = 'Temp';
  String timeRange = '24h';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider(widget.pondId));

    return Column(
      children: [
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Temp', 'pH', 'Turbidity', 'DO', 'Ammonia', 'CO2'].map((e) => GestureDetector(
              onTap: () => setState(() => selectedParam = e),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: selectedParam == e ? const Color(0xFF00BFFF) : Colors.transparent, width: 2))
                ),
                child: Text(e, style: TextStyle(color: selectedParam == e ? const Color(0xFF00BFFF) : Colors.grey)),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Time range
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFF112236), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF00BFFF)),
                SizedBox(width: 8),
                Text('LAST 24 HOURS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: historyAsync.when(
            data: (data) => _buildContentLayer(data),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF))),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildContentLayer(List<SensorReadingModel> data) {
    if (data.isEmpty) return const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));

    final points = <FlSpot>[];
    double maxVal = -1.0;
    double minVal = 10000.0;
    double sum = 0;
    
    // Ensure chronological order
    data.sort((a,b) => a.timestamp.compareTo(b.timestamp));

    for (int i=0; i<data.length; i++) {
        double v = 0;
        if(selectedParam == 'Temp') { v = data[i].temperature; }
        else if(selectedParam == 'pH') { v = data[i].ph; }
        else if(selectedParam == 'Turbidity') { v = data[i].turbidity; }
        else if(selectedParam == 'DO') { v = data[i].doLevel ?? 0.0; }
        else if(selectedParam == 'Ammonia') { v = data[i].ammoniaLevel ?? 0.0; }
        else if(selectedParam == 'CO2') { v = data[i].co2Level ?? 0.0; }
        
        // Map time to X-axis (0.0 to 23.5)
        double hourX = data[i].timestamp.hour + (data[i].timestamp.minute / 60.0);
        points.add(FlSpot(hourX, v));
        
        if (v > maxVal) { maxVal = v; }
        if (v < minVal) { minVal = v; }
        sum += v;
    }
    double avg = data.isNotEmpty ? sum / data.length : 0;

    String unit = '';
    if (selectedParam == 'Temp') { unit = '°C'; }
    else if (selectedParam == 'pH') { unit = 'pH'; }
    else if (selectedParam == 'Turbidity') { unit = 'NTU'; }
    else if (selectedParam == 'DO') { unit = 'mg/L'; }
    else if (selectedParam == 'Ammonia') { unit = 'mg/L'; }
    else if (selectedParam == 'CO2') { unit = 'mg/L'; }

    String formatValue(double v) {
      if (selectedParam == 'Ammonia') return '${v.toStringAsFixed(2)} $unit';
      if (selectedParam == 'Turbidity') return '${v.toStringAsFixed(0)} $unit';
      return '${v.toStringAsFixed(1)} $unit';
    }



    // Calculate width: 48 points * 25px per point = 1200px
    final double chartWidth = points.length * 25.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('REAL-TIME ENVIRONMENTAL CLASSIFICATION', 
            style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _InteractiveChartWidget(
            selectedParam: selectedParam,
            unit: unit,
            points: points,
            chartWidth: chartWidth,
          ),
          
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF00BFFF)),
              SizedBox(width: 8),
              Text('Summary Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statBox('AVERAGE', formatValue(avg))),
              const SizedBox(width: 8),
              Expanded(child: _statBox('HIGH', formatValue(maxVal))),
              const SizedBox(width: 8),
              Expanded(child: _statBox('LOW', formatValue(minVal))),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF112236), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InteractiveChartWidget extends StatefulWidget {
  final String selectedParam;
  final String unit;
  final List<FlSpot> points;
  final double chartWidth;

  const _InteractiveChartWidget({
    required this.selectedParam,
    required this.unit,
    required this.points,
    required this.chartWidth,
  });

  @override
  State<_InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<_InteractiveChartWidget> {
  late double minY;
  late double maxY;

  double get maxLimit {
    if (widget.selectedParam == 'Temp') return 40;
    if (widget.selectedParam == 'Turbidity') return 60;
    if (widget.selectedParam == 'pH') return 14;
    // defaults for DO, Ammonia, CO2
    if (widget.selectedParam == 'DO') return 20;
    if (widget.selectedParam == 'Ammonia') return 5;
    if (widget.selectedParam == 'CO2') return 30;
    return 100;
  }

  double get windowSize {
    if (widget.selectedParam == 'Temp') return 20;
    if (widget.selectedParam == 'Turbidity') return 30;
    if (widget.selectedParam == 'pH') return 7;
    // defaults
    if (widget.selectedParam == 'DO') return 10;
    if (widget.selectedParam == 'Ammonia') return 1.0;
    if (widget.selectedParam == 'CO2') return 15;
    return 20;
  }

  @override
  void initState() {
    super.initState();
    _resetView();
  }

  @override
  void didUpdateWidget(_InteractiveChartWidget oldWidget) {
    if (oldWidget.selectedParam != widget.selectedParam) {
      _resetView();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _resetView() {
    setState(() {
      minY = 0;
      maxY = windowSize;
    });
  }

  FlDotPainter _getDotPainter(FlSpot spot, double xPercentage, LineChartBarData bar, int index) {
    return FlDotCirclePainter(
      radius: 3,
      color: Colors.white,
      strokeWidth: 1.5,
      strokeColor: const Color(0xFF00BFFF),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF112236),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF00BFFF), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('${widget.selectedParam} (${widget.unit})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text('INTERACTIVE Y-AXIS ENABLED', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text('Range: ${minY.toStringAsFixed(1)} - ${maxY.toStringAsFixed(1)} ${widget.unit}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: _resetView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFFF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF00BFFF),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset View', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ─── Chart with Interactive Drag ───────────────────────────
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  double delta = details.delta.dy * -0.1;
                  minY = (minY + delta).clamp(0.0, maxLimit - windowSize);
                  maxY = (maxY + delta).clamp(windowSize, maxLimit);
                });
              },
              child: SizedBox(
                height: 260,
                child: Row(
                  children: [
                    // 1. Fixed Y-Axis Column (50px)
                    SizedBox(
                      width: 50,
                      child: LineChart(
                        LineChartData(
                          minX: 0, maxX: 1, // Only for spacing
                          minY: minY, maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                            getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                              getTitlesWidget: (val, meta) {
                                return Text(val.toStringAsFixed(widget.selectedParam == 'Ammonia' ? 2 : 1), 
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold));
                              }
                            )),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    
                    // 2. Scrollable Timeline
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: widget.chartWidth,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: 23.5,
                              minY: minY,
                              maxY: maxY,
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: const Color(0xFF112236),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((s) => LineTooltipItem(
                                      '${s.y.toStringAsFixed(widget.selectedParam == 'Ammonia' ? 2 : 1)} ${widget.unit}',
                                      const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold),
                                    )).toList();
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true, 
                                drawVerticalLine: true, 
                                verticalInterval: 2, // Every 2 hours
                                horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                                getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                                getDrawingVerticalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.03), strokeWidth: 1),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: true, 
                                  reservedSize: 32, 
                                  interval: 2, 
                                  getTitlesWidget: (val, meta) {
                                    if (val > 23.6) return const SizedBox();
                                    String text = '${val.toInt().toString().padLeft(2, '0')}:00';
                                    if (val >= 23.4) text = '23:59';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold)),
                                    );
                                  })),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: widget.points,
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  color: const Color(0xFF00BFFF),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: _getDotPainter,
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00BFFF).withValues(alpha: 0.1),
                                        const Color(0xFF00BFFF).withValues(alpha: 0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
