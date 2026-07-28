import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/cartera/models/cartera_models.dart';

class CarteraCalendar extends StatefulWidget {
  final List<CobroItem> cobros;
  final Function(CobroItem item)? onCobroTap;

  const CarteraCalendar({
    super.key,
    required this.cobros,
    this.onCobroTap,
  });

  @override
  State<CarteraCalendar> createState() => _CarteraCalendarState();
}

class _CarteraCalendarState extends State<CarteraCalendar> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final monthName = DateFormat('MMMM yyyy', 'es').format(_focusedMonth);

    // Map cobros to day numbers
    final Map<int, List<CobroItem>> cobrosByDay = {};
    for (final c in widget.cobros) {
      try {
        final dt = DateTime.parse(c.fechaVencimiento);
        if (dt.year == _focusedMonth.year && dt.month == _focusedMonth.month) {
          cobrosByDay.putIfAbsent(dt.day, () => []).add(c);
        }
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Month Header Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthName[0].toUpperCase() + monthName.substring(1),
                  style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Weekday Headers
            Row(
              children: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: AppTypography.caption,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Grid Days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (firstWeekday - 1) + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox.shrink();
                }
                final dayNumber = index - (firstWeekday - 1) + 1;
                final dayCobros = cobrosByDay[dayNumber] ?? [];

                Color? badgeColor;
                if (dayCobros.isNotEmpty) {
                  if (dayCobros.any((c) => c.estado == 'VENCIDA')) {
                    badgeColor = AppColors.error;
                  } else if (dayCobros.any((c) => c.estado == 'PENDIENTE')) {
                    badgeColor = AppColors.warning;
                  } else if (dayCobros.every((c) => c.estado == 'PAGADA')) {
                    badgeColor = AppColors.success;
                  }
                }

                return GestureDetector(
                  onTap: () {
                    if (dayCobros.isNotEmpty && widget.onCobroTap != null) {
                      widget.onCobroTap!(dayCobros.first);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: badgeColor != null
                          ? badgeColor.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: badgeColor != null
                          ? Border.all(color: badgeColor, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: AppTypography.body.copyWith(
                            fontWeight: dayCobros.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            color: badgeColor ?? theme.colorScheme.onSurface,
                          ),
                        ),
                        if (dayCobros.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Pagado', AppColors.success),
                _buildLegendItem('Pendiente', AppColors.warning),
                _buildLegendItem('En Mora', AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
