import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A month selector chip bar with ◄ / ► arrows.
///
/// Tapping the month opens a bottom sheet with year + month grid.
/// Tapping ◄/► changes the month with smooth animation.
class MonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  void _previousMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1, 1));
  }

  void _nextMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1, 1));
  }

  void _openMonthPicker(BuildContext context) {
    final currentYear = currentMonth.year;
    final currentM = currentMonth.month;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => _MonthPickerSheet(
        selectedYear: currentYear,
        selectedMonth: currentM,
        onSelected: (year, month) {
          Navigator.of(ctx).pop();
          onMonthChanged(DateTime(year, month, 1));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear =
        '${DateFormat.MMMM('es').format(currentMonth)} ${currentMonth.year}';
    final capitalized =
        monthYear[0].toUpperCase() + monthYear.substring(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        _ArrowButton(
          icon: Icons.chevron_left,
          onTap: _previousMonth,
        ),
        const SizedBox(width: AppSpacing.sm),

        // Month chip
        ActionChip(
          label: Text(
            capitalized,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _openMonthPicker(context),
          avatar: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          backgroundColor: AppColors.card,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Next
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: _nextMonth,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(50),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Month picker bottom sheet
// ─────────────────────────────────────────────────────────────

class _MonthPickerSheet extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final void Function(int year, int month) onSelected;

  const _MonthPickerSheet({
    required this.selectedYear,
    required this.selectedMonth,
    required this.onSelected,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _selectedMonth;

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril',
    'Mayo', 'Junio', 'Julio', 'Agosto',
    'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.selectedYear;
    _selectedMonth = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '$_year',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Month grid
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: List.generate(12, (i) {
              final month = i + 1;
              final isSelected = month == _selectedMonth && _year == widget.selectedYear;
              return ChoiceChip(
                label: Text(_months[i]),
                selected: isSelected,
                onSelected: (_) {
                  widget.onSelected(_year, month);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
