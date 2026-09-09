import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Estilos compartidos para las familias de tarjeta de la app.
///
/// Cambiar el color, radio, padding o tipografía de las tarjetas se hace
/// SOLO en este archivo y se aplica a toda la app sin importar el rol
/// (admin, cobrador, residente).
///
/// Familias:
///  1. [kpi]    — tarjetas de métrica (KPICard, MiniStatCard).
///  2. [cobro]  — tarjetas de cobro/estado (CobroCard, EstadoCuentaCard).
///  3. [badge]  — badges/píldoras de estado dentro de tarjetas.
///  4. [list]   — tarjetas de lista genérica (solicitudes, actividad).
abstract final class AppCardStyles {
  // ══ Tipografías por familia ══════════════════════════════════════

  /// Título principal de cualquier tarjeta.
  static TextStyle get cardTitle => AppTypography.cardTitle;

  /// Monto / cifra destacada de tarjeta.
  static TextStyle get cardValue => AppTypography.cardValue;

  /// Texto de etiqueta secundaria dentro de tarjeta.
  static TextStyle get cardLabel => AppTypography.label;

  /// Caption de tarjeta (fechas, subtítulos).
  static TextStyle get cardCaption => AppTypography.caption;

  /// Texto de badge/píldora compacta.
  static TextStyle get badgeText => AppTypography.micro;

  /// Valor de tarjeta KPI (usa [AppTypography.cardValue] con color dinámico).
  static TextStyle kpiValue(Color color) =>
      AppTypography.cardValue.copyWith(color: color);

  /// Título de tarjeta KPI.
  static TextStyle get kpiTitle =>
      AppTypography.caption.copyWith(color: AppColors.textSecondary);

  /// Título de tarjeta de cobro (dinámico light/dark).
  static TextStyle get cobroTitle => AppTypography.cardTitle.copyWith(
        color: AppColors.elevatedCardText,
      );

  /// Texto de residente/ubicación en tarjeta de cobro.
  static TextStyle get cobroSubtitle => AppTypography.label.copyWith(
        color: AppColors.elevatedCardTextSecondary,
      );

  /// Monto de tarjeta de cobro con color semántico opcional.
  static TextStyle cobroValue({Color? color}) => AppTypography.cardValue
      .copyWith(color: color ?? AppColors.elevatedCardText);

  // ══ Contenedores ═════════════════════════════════════════════════

  /// Decoración base de tarjeta elevada (borde + sombra suave).
  static BoxDecoration elevatedCard(BuildContext context,
      {Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.elevatedCard,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(
        color: borderColor ?? AppColors.elevatedCardBorder,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Decoración de badge/píldora con color semántico.
  static BoxDecoration badge(Color color, {double alpha = 0.15}) =>
      BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      );

  /// Decoración de chip de concepto dentro de tarjeta.
  static BoxDecoration conceptChip(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      );

  /// Padding interno estándar de tarjeta.
  static const EdgeInsets cardPadding =
      EdgeInsets.all(AppSpacing.cardInnerPadding);
}
