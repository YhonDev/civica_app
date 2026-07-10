import 'models/cartera_models.dart';

class CarteraRepository {
  /// Devuelve el resumen general de la cartera.
  Future<CarteraResumen> getCarteraResumen() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Mismos datos que cuadran con el Dashboard:
    // 65 Pagados (7.800.000)
    // 17 Pendientes (2.040.000)
    // 6 Mora (720.000)
    return const CarteraResumen(
      totalPendiente: 2040000,
      totalMora: 720000,
      totalPagado: 7800000,
      cantidadPendientes: 17,
      cantidadMora: 6,
      cantidadPagados: 65,
    );
  }

  /// Devuelve la lista detallada de cobros (mockeando 88 propietarios totales).
  Future<List<CobroItem>> getCobros() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final List<CobroItem> cobros = [];

    // Generar 17 pendientes
    for (var i = 0; i < 17; i++) {
      cobros.add(
        CobroItem(
          id: 'P-$i',
          nombre: 'Pendiente Propietario $i',
          casa: 'Casa ${100 + i}',
          etapa: 'Etapa 1',
          saldo: 120000,
          estado: 'Pendiente',
          modalidad: i % 2 == 0 ? 'Mensual' : 'Quincenal',
        ),
      );
    }

    // Generar 6 en mora
    for (var i = 0; i < 6; i++) {
      cobros.add(
        CobroItem(
          id: 'M-$i',
          nombre: 'Mora Propietario $i',
          casa: 'Casa ${200 + i}',
          etapa: 'Etapa 2',
          saldo: 120000 * (i + 1).toDouble(), // Algunos deben más de un mes
          estado: 'Mora',
          modalidad: 'Mensual',
        ),
      );
    }

    // Generar 65 pagados
    for (var i = 0; i < 65; i++) {
      cobros.add(
        CobroItem(
          id: 'PG-$i',
          nombre: 'Pagado Propietario $i',
          casa: 'Casa ${300 + i}',
          etapa: 'Etapa ${i % 3 + 1}',
          saldo: 0,
          estado: 'Pagado',
          modalidad: i % 3 == 0 ? 'Mensual' : 'Semanal',
        ),
      );
    }

    // Ordenar aleatoriamente o alfabéticamente (por ahora devolvemos tal cual, la UI puede filtrar)
    return cobros;
  }
}
