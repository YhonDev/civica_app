import '../../core/network/api_client.dart';

/// Consulta tarifas vigentes desde el backend.
/// El admin puede editar los montos; siempre usar este repositorio en runtime.
class TarifasRepository {
  Future<TarifasVigentes> getVigentes(String conjuntoId) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/tarifas/vigentes',
      queryParameters: {'conjuntoId': conjuntoId},
    );
    final data = response.data!;
    final tarifas = data['tarifas'] as Map<String, dynamic>;

    int? montoPesos(Map<String, dynamic>? t) =>
        t == null ? null : t['montoPesos'] as int?;

    return TarifasVigentes(
      cuotaMensualPesos: data['cuotaMensualPesos'] as int?,
      mensual: montoPesos(tarifas['MENSUAL'] as Map<String, dynamic>?),
      quincenal: montoPesos(tarifas['QUINCENAL'] as Map<String, dynamic>?),
      semanal: montoPesos(tarifas['SEMANAL'] as Map<String, dynamic>?),
    );
  }
}

class TarifasVigentes {
  final int? cuotaMensualPesos;
  final int? mensual;
  final int? quincenal;
  final int? semanal;

  const TarifasVigentes({
    this.cuotaMensualPesos,
    this.mensual,
    this.quincenal,
    this.semanal,
  });

  int? montoParaFrecuencia(String frecuencia) => switch (frecuencia) {
        'SEMANAL' => semanal,
        'QUINCENAL' => quincenal,
        'MENSUAL' => mensual,
        _ => mensual,
      };
}
