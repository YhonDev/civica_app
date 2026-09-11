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
///  1. [kpi]    — tarjetas de métrica (KPICard, MiniStatCard, ModuleSummaryCard).
///  2. [cobro]  — tarjetas de cobro/estado (CobroCard, EstadoCuentaCard).
///  3. [badge]  — badges/píldoras de estado dentro de tarjetas.
///  4. [list]   — tarjetas de lista genérica (SolicitudCard, filas de actividad).
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

  /// Valor de tarjeta KPI (cardValue con color dinámico).
  static TextStyle kpiValue(Color color) =>
      AppTypography.cardValue.copyWith(color: color);

  /// Valor grande de resumen de módulo (cifra protagonista).
  static TextStyle bigStat(Color color) =>
      AppTypography.title.copyWith(fontWeight: FontWeight.w800, color: color);

  /// Valor de tarjeta KPI compacta (MiniStatCard).
  static TextStyle kpiStatValue(Color color) =>
      AppTypography.subtitle.copyWith(color: color);

  /// Título de tarjeta KPI.
  static TextStyle get kpiTitle =>
      AppTypography.caption.copyWith(color: AppColors.textSecondary);

  /// Etiqueta de tarjeta KPI compacta.
  static TextStyle get kpiLabel =>
      AppTypography.small.copyWith(color: AppColors.textSecondary);

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

  /// Saldo protagonista de la tarjeta de estado de cuenta.
  static TextStyle get heroValue =>
      AppTypography.title.copyWith(fontWeight: FontWeight.w700);

  /// Texto de chip de metadatos (ej. "Tarifa: $ 40.000").
  static TextStyle get metaChipText => AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  /// Título de tarjeta de lista.
  static TextStyle get listTitle =>
      AppTypography.body.copyWith(fontWeight: FontWeight.w600);

  /// Subtítulo de tarjeta de lista.
  static TextStyle get listSubtitle => AppTypography.small.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      );

  /// Meta-texto de tarjeta de lista (fechas, códigos).
  static TextStyle get listMeta => AppTypography.small.copyWith(
        color: AppColors.textSecondary,
      );

  /// Etiqueta de fila en tarjeta de lista (valor con peso normal).
  static TextStyle get listRowLabel => AppTypography.body.copyWith(
        color: AppColors.textSecondary,
      );

  /// Texto del Call to Action al pie de tarjeta.
  static TextStyle get cardAction => AppTypography.bodyMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      );

  /// Texto de píldora de estado (StatusBadge).
  static TextStyle get badgePillText => AppTypography.small;

  /// Texto de estado coloreado dentro de tarjeta de lista.
  static TextStyle statusText(Color color) =>
      AppTypography.small.copyWith(color: color, fontWeight: FontWeight.w600);

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

  /// Tarjeta de lista genérica (sin borde, sombra muy suave).
  static BoxDecoration listCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Tarjeta protagonista (estado de cuenta) — sombra un poco más marcada.
  static BoxDecoration heroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Tarjeta de resumen de módulo con borde y glow opcionales.
  static BoxDecoration sectionCard(
    BuildContext context, {
    Color? borderColor,
    Color? glowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(
        color: borderColor ?? AppColors.border.withValues(alpha: 0.6),
        width: glowColor != null ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor ??
              Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Tarjeta KPI compacta con tinte del color semántico.
  static BoxDecoration tintedCard(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      );

  /// Contenedor del ícono líder en tarjetas de lista.
  static BoxDecoration iconTile(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      );

  /// Decoración de badge/píldora con color semántico.
  static BoxDecoration badge(
    Color color, {
    double alpha = 0.15,
    double radius = 12,
    bool withBorder = true,
  }) =>
      BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(radius),
        border: withBorder
            ? Border.all(color: color.withValues(alpha: 0.5))
            : null,
      );

  /// Chip de metadatos (fondo surface + borde tenue).
  static BoxDecoration metaChip() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
