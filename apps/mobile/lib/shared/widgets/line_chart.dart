import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A data point for the line chart.
class ChartPoint {
  final String day;
  final double value;

  const ChartPoint({required this.day, required this.value});
}

/// A minimal single-line chart with day labels on the X axis.
///
/// Size: full width, ~200 height. Uses a [CustomPainter].
class LineChartWidget extends StatelessWidget {
  final List<ChartPoint> points;
  final String title;
  final double height;

  const LineChartWidget({
    super.key,
    required this.points,
    required this.title,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Sin datos',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.subtitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: _LineChartPainter(points: points),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxValue = points.fold<double>(0, (max, p) => p.value > max ? p.value : max);
    final minValue = points.fold<double>(double.infinity, (min, p) => p.value < min ? p.value : min);
    final range = (maxValue - minValue).clamp(1, double.infinity);

    final paddingLeft = 32.0;
    const paddingRight = 16.0;
    const paddingTop = 8.0;
    const paddingBottom = 24.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Helper: point to canvas offset
    Offset mapPoint(ChartPoint p) {
      final x = paddingLeft + (points.indexOf(p) / (points.length - 1).clamp(1, points.length)) * chartWidth;
      final y = paddingTop + chartHeight - ((p.value - minValue) / range) * chartHeight;
      return Offset(x, y);
    }

    // ── Grid lines (thin, subtle) ──
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (var i = 1; i < 4; i++) {
      final y = paddingTop + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // ── Line ──
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final pos = mapPoint(points[i]);
      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // ── Area fill under line ──
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    if (points.isNotEmpty) {
      final last = mapPoint(points.last);
      final first = mapPoint(points.first);
      fillPath.lineTo(last.dx, paddingTop + chartHeight);
      fillPath.lineTo(first.dx, paddingTop + chartHeight);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // ── Dots ──
    final dotPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;

    final dotStrokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final point in points) {
      final pos = mapPoint(point);
      canvas.drawCircle(pos, 3.5, dotPaint);
      canvas.drawCircle(pos, 3.5, dotStrokePaint);
    }

    // ── X axis labels ──
    for (var i = 0; i < points.length; i++) {
      // Show every Nth label to avoid crowding
      if (points.length > 10 && i % (points.length ~/ 5) != 0 && i != 0 && i != points.length - 1) continue;

      final pos = mapPoint(points[i]);
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].day,
          style: AppTypography.micro.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.textDisabled,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, paddingTop + chartHeight + 6));
    }

    // ── Y axis label (max) ──
    if (points.isNotEmpty) {
      final maxPoint = points.reduce((a, b) => a.value > b.value ? a : b);
      final maxPos = mapPoint(maxPoint);
      final tp = TextPainter(
        text: TextSpan(
          text: _formatValue(maxPoint.value),
          style: AppTypography.micro.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.textDisabled,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(paddingLeft - tp.width - 4, maxPos.dy - tp.height / 2),
      );
    }
  }

  String _formatValue(double value) => AppCurrency.formatCompact(value);

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
