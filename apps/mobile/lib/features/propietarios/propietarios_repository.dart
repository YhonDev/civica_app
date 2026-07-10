import 'models/propietarios_models.dart';
import '../../core/constants/mock_data.dart';

class PropietariosRepository {
  /// Obtiene el resumen de la comunidad.
  Future<PropietarioResumen> getResumen() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Contamos casas totales (deberían ser 5 según MockData)
    int totalCasas = 0;
    for (var casas in MockData.casasPorManzana.values) {
      totalCasas += casas.length;
    }

    final int ocupadas = MockData.propietarios.length;
    
    return PropietarioResumen(
      totalPropiedades: totalCasas,
      ocupadas: ocupadas,
      vacantes: totalCasas - ocupadas,
    );
  }

  /// Obtiene la lista completa de propietarios en la comunidad.
  Future<List<PropietarioItem>> getPropietarios() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final List<PropietarioItem> propietarios = [];
    
    for (int i = 0; i < MockData.propietarios.length; i++) {
      final p = MockData.propietarios[i];
      
      // Parsear monto a double
      String montoStr = p['monto'].replaceAll('\$', '').replaceAll('.', '');
      double saldo = double.tryParse(montoStr) ?? 0.0;

      propietarios.add(
        PropietarioItem(
          id: 'P-$i',
          nombre: p['nombre'],
          telefono: '+57 300 000 000$i',
          casa: p['casa'],
          etapa: p['etapa'],
          estadoFinanciero: p['estado'],
          saldoPendiente: saldo,
        ),
      );
    }

    return propietarios;
  }
}
