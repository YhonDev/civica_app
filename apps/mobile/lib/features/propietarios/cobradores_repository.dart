import 'models/cobradores_models.dart';
import '../../core/constants/mock_data.dart';

class CobradoresRepository {
  Future<CobradorResumen> getResumen() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final total = MockData.cobradores.length;
    final activos = MockData.cobradores.where((c) => c['estado'] == 'Activo').length;

    return CobradorResumen(
      totalCobradores: total,
      activos: activos,
      inactivos: total - activos,
    );
  }

  Future<List<CobradorItem>> getCobradores() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final List<CobradorItem> cobradores = [];
    
    for (int i = 0; i < MockData.cobradores.length; i++) {
      final c = MockData.cobradores[i];
      cobradores.add(
        CobradorItem(
          id: 'C-$i',
          nombre: c['nombre'],
          telefono: '+57 311 000 000$i',
          correo: 'cobrador$i@civicapago.com',
          zonas: List<String>.from(c['etapasAsignadas'] ?? []),
          activo: c['estado'] == 'Activo',
          pagosRegistradosSemana: 0,
        ),
      );
    }

    return cobradores;
  }
}
