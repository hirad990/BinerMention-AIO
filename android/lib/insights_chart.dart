import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'localized_text.dart';

class InsightsTrendChart extends StatelessWidget {
  const InsightsTrendChart({super.key, required this.points});
  final List points;

  @override
  Widget build(BuildContext context) {
    final values = points.whereType<Map>().map((item) => <String, dynamic>{
      'date': item['date']?.toString() ?? '',
      'views': int.tryParse(item['views']?.toString() ?? '') ?? 0,
    }).toList();
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.show_chart_rounded, color: color, size: 19)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BinerLocalizedText('بازدیدهای ۷ روز اخیر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            BinerLocalizedText('بر اساس رویدادهای واقعی ثبت‌شده', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
          if (values.isNotEmpty) Text(values.fold<int>(0, (sum, item) => sum + (item['views'] as int)).toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        const SizedBox(height: 14),
        if (values.isEmpty)
          const SizedBox(height: 150, child: Center(child: BinerLocalizedText('هنوز داده‌ای برای نمودار وجود ندارد.', style: TextStyle(color: Colors.grey))))
        else
          SizedBox(height: 174, width: double.infinity, child: CustomPaint(
            painter: _InsightsLinePainter(
              values: values,
              lineColor: color,
              gridColor: Theme.of(context).dividerColor.withValues(alpha: .65),
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )),
      ]),
    );
  }
}

class _InsightsLinePainter extends CustomPainter {
  const _InsightsLinePainter({required this.values, required this.lineColor, required this.gridColor, required this.textColor});
  final List<Map<String, dynamic>> values;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    const left = 30.0, right = 8.0, top = 8.0, bottom = 28.0;
    final plot = Rect.fromLTRB(left, top, math.max(left + 1, size.width - right).toDouble(), size.height - bottom);
    final maxValue = values.fold<int>(1, (m, item) { final value = item['views'] as int; return value > m ? value : m; });
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    final labelStyle = TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w500);
    for (var i = 0; i <= 3; i++) {
      final y = plot.top + plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final label = TextPainter(text: TextSpan(text: (maxValue * (3 - i) / 3).round().toString(), style: labelStyle), textDirection: TextDirection.ltr)..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final dx = values.length == 1 ? 0.0 : plot.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i]['views'] as int;
      points.add(Offset(plot.left + dx * i, plot.bottom - (value / maxValue) * plot.height));
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) line.lineTo(points[i].dx, points[i].dy);
    final area = Path.from(line)..lineTo(points.last.dx, plot.bottom)..lineTo(points.first.dx, plot.bottom)..close();
    final fill = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lineColor.withValues(alpha: .22), lineColor.withValues(alpha: .01)]).createShader(plot);
    canvas.drawPath(area, fill);
    canvas.drawPath(line, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
    for (var i = 0; i < values.length; i++) {
      final raw = values[i]['date'] as String;
      final parsed = DateTime.tryParse(raw);
      final label = parsed == null ? '' : parsed.day.toString();
      final tp = TextPainter(text: TextSpan(text: label, style: labelStyle), textDirection: TextDirection.ltr)..layout();
      final x = (points[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width).toDouble();
      tp.paint(canvas, Offset(x, plot.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _InsightsLinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor || oldDelegate.gridColor != gridColor;
}
