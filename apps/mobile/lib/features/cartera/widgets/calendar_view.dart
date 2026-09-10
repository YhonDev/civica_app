import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/cartera_models.dart';

class CalendarView extends StatefulWidget {
  final List<CobroItem> cobros;
  final void Function(DateTime date, List<CobroItem> cobros)? onDaySelected;

  const CalendarView({
    super.key,
    required this.cobros,
    this.onDaySelected,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;

    return Column(
      children: [
        // Selector de Mes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _prevMonth,
            ),
            Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Cabecera de días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _WeekdayLabel('L'),
            _WeekdayLabel('M'),
            _WeekdayLabel('M'),
            _WeekdayLabel('J'),
            _WeekdayLabel('V'),
            _WeekdayLabel('S'),
            _WeekdayLabel('D'),
          ],
        ),
        const Divider(),
        // Cuadrícula del mes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth + firstDayOffset,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index < firstDayOffset) {
              return const SizedBox.shrink();
            }

            final day = index - firstDayOffset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

            // Buscar cobros que vencen este día
            final dayCobros = widget.cobros.where((c) {
              if (c.fechaVencimiento.isEmpty) return false;
              // Normalizar fechaVencimiento a formato YYYY-MM-DD
              final String cleanFecha = c.fechaVencimiento.split('T')[0];
              return cleanFecha == dateStr;
            }).toList();

            Color? dotColor;
            if (dayCobros.isNotEmpty) {
              final statusLower = dayCobros.map((c) => c.estado.toLowerCase()).toSet();
              if (statusLower.contains('mora') || statusLower.contains('vencida')) {
                dotColor = AppColors.error;
              } else if (statusLower.contains('pendiente')) {
                dotColor = AppColors.warning;
              } else if (statusLower.contains('pagado') || statusLower.contains('pagada')) {
                dotColor = AppColors.success;
              }
            }

            final isToday = DateUtils.isSameDay(DateTime.now(), date);

            return InkWell(
              onTap: () {
                if (widget.onDaySelected != null) {
                  widget.onDaySelected!(date, dayCobros);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  color: isToday ? AppColors.primary.withValues(alpha: 0.05) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: AppTypography.body.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: dayCobros.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    if (dotColor != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
