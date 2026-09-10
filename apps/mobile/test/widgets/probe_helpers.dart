/// Helpers compartidos por las sondas de diseño (`*_layout_probe_test.dart`,
/// `*_keyboard_probe_test.dart`).
/// Estandarizan tres piezas que antes se copiaban suite por suite:
/// 1. Viewport: tamaño físico + DPR 1.0 + teardown que restaura la vista.
/// 2. Teclado: insets simulados de 280px de alto en el borde inferior.
/// 3. Geometría: aserciones de ancho máximo, centrado y gutters simétricos.
///
/// Las aserciones son tolerantes (±0.5px) porque los puntos flotantes de
/// MediaQuery/scroll pueden variar por sub-pixel entre dispositivos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Alto simulado del teclado en píxeles lógicos.
const double kFakeKeyboardHeight = 280;

/// Gutter mínimo de pantalla en píxeles lógicos (`AppSpacing.screenPadding`).
const double kMinGutter = 20;

/// Ancho máximo del contenido de formularios/modales
/// (`AppBreakpoints.maxFormWidth`).
const double kMaxFormWidth = 440;

/// Configura el viewport del tester para una prueba de layout.
///
/// Fija [screen] como tamaño físico con `devicePixelRatio = 1.0` (los tamaños
/// lógicos coinciden con los físicos) y registra el `reset()` en los teardowns,
/// de modo que un solo `addTearDown` revierte tamaño, DPR e insets.
void setProbeViewport(
  WidgetTester tester,
  Size screen, {
  bool keyboard = false,
}) {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewInsets =
      keyboard ? const FakeViewPadding(bottom: kFakeKeyboardHeight) : FakeViewPadding.zero;
  // reset() revierte physicalSize, dpr e insets de una sola vez.
  addTearDown(tester.view.reset);
}

/// Rectángulo del primer [Type] hallado bajo el primer [Type] ancestro.
///
/// Patrón común de las sondas: localizar el contenido interno de un widget
/// (p. ej. el `Column` dentro de un sheet) para medir su geometría real.
Rect contentRectOf(WidgetTester tester, Type ancestor, Type descendant) {
  return tester.getRect(
    find.descendant(
      of: find.byType(ancestor),
      matching: find.byType(descendant),
    ).first,
  );
}

/// Afirmaciones de geometría para un panel de contenido acotado y centrado.
///
/// - [rect]: rectángulo del contenido medido con `tester.getRect(...)`.
/// - [screenWidth]: ancho de pantalla donde vive el contenido.
/// - [expectedLeft]: gutter izquierdo esperado (p. ej. `(820 - 440) / 2`).
/// - [label]: nombre del caso, para los `reason` de los `expect`.
/// - [maxWidth]: ancho máximo permitido (por defecto `kMaxFormWidth`).
/// - [minGutter]: gutter mínimo permitido (por defecto `kMinGutter`).
///
/// Verifica: ancho ≤ [maxWidth], gutter izquierdo ≈ [expectedLeft] (±0.5px),
/// gutters simétricos (izq ≈ der) y gutter izquierdo ≥ [minGutter].
void expectCenteredContentGeometry(
  Rect rect, {
  required double screenWidth,
  required double expectedLeft,
  required String label,
  double maxWidth = kMaxFormWidth,
  double minGutter = kMinGutter,
}) {
  expect(
    rect.width,
    lessThanOrEqualTo(maxWidth),
    reason: '$label: el contenido se estira más allá de maxFormWidth',
  );

  final left = rect.left;
  final right = screenWidth - rect.right;
  expect(
    left,
    closeTo(expectedLeft, 0.5),
    reason: '$label: gutter izquierdo $left ≠ esperado $expectedLeft',
  );
  expect(
    right,
    closeTo(left, 0.5),
    reason: '$label: asimétrico — izq $left vs der $right',
  );
  expect(
    left,
    greaterThanOrEqualTo(minGutter),
    reason: '$label: el modal pega el contenido al borde',
  );
}
