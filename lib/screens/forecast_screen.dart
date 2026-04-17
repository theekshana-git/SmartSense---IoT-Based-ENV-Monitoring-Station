import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  Map<String, dynamic>? _forecast;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final data = await ApiService.fetchForecast();
    if (mounted) setState(() { _forecast = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────
            Container(
              color: const Color(0xFF1A2340),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Row(
                children: [
                  Icon(Icons.cloud_outlined, color: Color(0xFF378ADD), size: 24),
                  SizedBox(width: 10),
                  Text('Weather Outlook', style: TextStyle(
                    color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  )),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF378ADD)))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: const Color(0xFF378ADD),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildMainCard(),
                          const SizedBox(height: 16),
                          _buildPressureChart(),
                          const SizedBox(height: 16),
                          _buildHourlyRow(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main status card ────────────────────────────────────────
  Widget _buildMainCard() {
    final f = _forecast!;
    final status   = f['status']          as String? ?? '--';
    final risk     = f['risk']            as String? ?? '--';
    final conf     = f['confidence']      as int?    ?? 0;
    final trend    = (f['pressure_trend'] as num?)?.toDouble() ?? 0.0;
    final window   = f['time_window']     as String? ?? '--';
    final wind     = f['wind_forecast']   ?? '--';
    final isStorm  = status.toLowerCase().contains('storm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2340),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(status, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
              ))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: isStorm ? AppColors.redL : AppColors.greenL,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(risk, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: isStorm ? AppColors.red : AppColors.greenDk,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pressure is ${trend < 0 ? "dropping" : "rising"} at '
            '${trend.toStringAsFixed(1)} hPa/hr. '
            '${isStorm ? "Storm expected" : "Conditions indicate"} within $window.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _FcStat(label: 'Pressure', value: '${trend.toStringAsFixed(1)} hPa/h'),
            const SizedBox(width: 8),
            _FcStat(label: 'Confidence', value: '$conf%'),
            const SizedBox(width: 8),
            _FcStat(label: 'Window', value: window),
            const SizedBox(width: 8),
            _FcStat(label: 'Wind', value: wind.toString()),
          ]),
        ],
      ),
    );
  }

  // ── Pressure trend chart ────────────────────────────────────
  Widget _buildPressureChart() {
    final history = (_forecast!['pressure_history'] as List?)
        ?.map((e) => (e as num).toDouble()).toList()
        ?? [1015.0, 1014.2, 1013.0, 1011.5, 1009.8, 1007.4, 1005.2, 1003.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Barometric Pressure — Last 6 Hours',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _PressureChartPainter(history),
              size: const Size(double.infinity, 90),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['6h ago', '4h', '2h', 'Now'].map((t) => Text(t,
              style: TextStyle(fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)))).toList(),
          ),
        ],
      ),
    );
  }

  // ── Hourly outlook row ──────────────────────────────────────
  Widget _buildHourlyRow() {
    final isStorm = (_forecast!['status'] as String? ?? '').toLowerCase().contains('storm');
    final hours = [
      (label: 'Now', emoji: '🌤', temp: '34°', warn: false),
      (label: '+2h', emoji: '🌥', temp: '32°', warn: false),
      (label: '+4h', emoji: isStorm ? '⛈' : '🌦', temp: '28°', warn: isStorm),
      (label: '+6h', emoji: isStorm ? '🌩' : '🌧', temp: '26°', warn: isStorm),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('HOURLY OUTLOOK', style: AppText.sectionLabel.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        ),
        Row(
          children: hours.map((h) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: h.warn ? AppColors.redL : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: h.warn ? AppColors.redMd : Colors.black.withOpacity(0.07),
                  width: 0.5,
                ),
              ),
              child: Column(children: [
                Text(h.label, style: TextStyle(
                  fontSize: 11,
                  color: h.warn ? AppColors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 8),
                Text(h.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(h.temp, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: h.warn ? AppColors.red : Theme.of(context).colorScheme.onSurface)),
              ]),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── Mini stat cell (inside forecast card) ────────────────────
class _FcStat extends StatelessWidget {
  final String label, value;
  const _FcStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Pressure trend chart painter ─────────────────────────────
class _PressureChartPainter extends CustomPainter {
  final List<double> points;
  const _PressureChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b) - 2;
    final max = points.reduce((a, b) => a > b ? a : b) + 2;
    final range = max - min;
    final xStep = size.width / (points.length - 1);

    Offset toOff(int i) => Offset(
      i * xStep,
      size.height - ((points[i] - min) / range) * size.height,
    );

    // Grid lines
    final gridP = Paint()..color = AppColors.blue.withOpacity(0.08)..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
    }

    // Area fill
    final fillPath = Path();
    fillPath.moveTo(0, toOff(0).dy);
    for (int i = 1; i < points.length; i++) fillPath.lineTo(toOff(i).dx, toOff(i).dy);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.blue.withOpacity(0.18), AppColors.blue.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    final linePath = Path();
    linePath.moveTo(toOff(0).dx, toOff(0).dy);
    for (int i = 1; i < points.length; i++) linePath.lineTo(toOff(i).dx, toOff(i).dy);
    canvas.drawPath(linePath, Paint()
      ..color = AppColors.blue..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // End dot
    final last = toOff(points.length - 1);
    canvas.drawCircle(last, 4, Paint()..color = AppColors.blue);
    canvas.drawCircle(last, 4, Paint()
      ..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}