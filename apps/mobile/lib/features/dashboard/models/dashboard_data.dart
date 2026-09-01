import 'package:equatable/equatable.dart';

/// Response from GET /dashboard/administrador?mes=X&anio=Y
class DashboardData extends Equatable {
  final int mes;
  final int anio;
  final double recaudoMes;
  final double metaMensual;
  final int pagaron;
  final int pendientes;
  final double mora;
  final double porcentaje;
  final List<EvolucionPunto> evolucion;
  final List<ModalidadItem> modalidades;
  final List<CobroEstadoItem> estadosCobro;
  final List<ActividadItem> actividadReciente;

  // Nuevas métricas Comunidad
  final int totalResidentes;
  final int nuevosResidentesSemana;

  // Nuevas métricas Cobros
  final List<CobroSemanaItem> cobrosPorSemana;

  // Centro de atencion
  final int solicitudesPendientes;
  final int residentesMora;
  final int pagosRevision;

  // Nuevos campos reportes anuales
  final double acumuladoAnual;
  final double metaAnual;
  final List<MesHistorico> historialMeses;

  const DashboardData({
    required this.mes,
    required this.anio,
    required this.recaudoMes,
    required this.metaMensual,
    required this.pagaron,
    required this.pendientes,
    required this.mora,
    required this.porcentaje,
    required this.evolucion,
    required this.modalidades,
    required this.estadosCobro,
    required this.actividadReciente,
    this.totalResidentes = 0,
    this.nuevosResidentesSemana = 0,
    this.cobrosPorSemana = const [],
    this.solicitudesPendientes = 0,
    this.residentesMora = 0,
    this.pagosRevision = 0,
    required this.acumuladoAnual,
    required this.metaAnual,
    required this.historialMeses,
  });

  /// Crea [DashboardData] desde la respuesta JSON del backend.
  ///
  /// [totalResidentesOverride] permite inyectar el total real de residentes
  /// (obtenido del repository vía una segunda llamada API), ya que el JSON
  /// del endpoint /dashboard/administrador no incluye este dato.
  factory DashboardData.fromJson(
    Map<String, dynamic> json, {
    int totalResidentesOverride = 0,
  }) {
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final estadoCobrosMap = json['estadoCobros'] as Map<String, dynamic>? ?? {};

    final pagaron = int.tryParse(resumen['pagaron']?.toString() ?? '') ?? 0;
    final pendientes = int.tryParse(resumen['pendientes']?.toString() ?? '') ?? 0;
    final residentesMora =
        int.tryParse(json['residentesMora']?.toString() ?? '') ?? 0;

    final pagadosPct =
        double.tryParse(estadoCobrosMap['pagados']?.toString() ?? '') ?? 0;
    final pendientesPct =
        double.tryParse(estadoCobrosMap['pendientes']?.toString() ?? '') ?? 0;
    final moraPct = 100 - pagadosPct - pendientesPct;

    return DashboardData(
      mes: int.tryParse(json['mes']?.toString() ?? '') ?? 0,
      anio: int.tryParse(json['anio']?.toString() ?? '') ?? 0,
      recaudoMes:
          (double.tryParse(resumen['recaudoTotal']?.toString() ?? '') ?? 0) /
              100,
      metaMensual:
          (double.tryParse(resumen['metaMensual']?.toString() ?? '') ?? 0) /
              100,
      pagaron: pagaron,
      pendientes: pendientes,
      mora: (double.tryParse(resumen['moraTotal']?.toString() ?? '') ?? 0) /
          100,
      porcentaje:
          double.tryParse(resumen['porcentajeMeta']?.toString() ?? '') ?? 0,
      evolucion: (json['evolucion'] as List<dynamic>?)
              ?.map((e) => EvolucionPunto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modalidades: (json['modalidades'] as List<dynamic>?)
              ?.map((e) => ModalidadItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estadosCobro: [
        CobroEstadoItem(
          estado: 'Pagados',
          porcentaje: pagadosPct,
          cantidad: pagaron,
        ),
        CobroEstadoItem(
          estado: 'Pendientes',
          porcentaje: pendientesPct,
          cantidad: pendientes,
        ),
        CobroEstadoItem(
          estado: 'En mora',
          porcentaje: moraPct < 0 ? 0 : moraPct,
          cantidad: residentesMora,
        ),
      ],
      actividadReciente: (json['actividad'] as List<dynamic>?)
              ?.map((e) => ActividadItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalResidentes: totalResidentesOverride,
      nuevosResidentesSemana:
          int.tryParse(json['nuevosResidentesSemana']?.toString() ?? '') ?? 0,
      solicitudesPendientes:
          int.tryParse(json['solicitudesPendientes']?.toString() ?? '') ?? 0,
      residentesMora: residentesMora,
      pagosRevision:
          int.tryParse(estadoCobrosMap['revision']?.toString() ?? '') ?? 0,
      cobrosPorSemana: (json['cobrosPorSemana'] as List<dynamic>?)
              ?.map((s) => CobroSemanaItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      acumuladoAnual:
          (double.tryParse(json['acumuladoAnual']?.toString() ?? '') ?? 0) /
              100,
      metaAnual:
          (double.tryParse(json['metaAnual']?.toString() ?? '') ?? 0) / 100,
      historialMeses: (json['historialMeses'] as List<dynamic>?)
              ?.map((e) => MesHistorico.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        mes,
        anio,
        recaudoMes,
        metaMensual,
        pagaron,
        pendientes,
        mora,
        porcentaje,
        evolucion,
        modalidades,
        estadosCobro,
        actividadReciente,
        totalResidentes,
        nuevosResidentesSemana,
        cobrosPorSemana,
        solicitudesPendientes,
        residentesMora,
        pagosRevision,
        acumuladoAnual,
        metaAnual,
        historialMeses,
      ];
}

class EvolucionPunto extends Equatable {
  final String dia;
  final double valor;

  const EvolucionPunto({required this.dia, required this.valor});

  factory EvolucionPunto.fromJson(Map<String, dynamic> json) {
    return EvolucionPunto(
      dia: json['dia'] as String? ?? '',
      valor: (double.tryParse(json['valor']?.toString() ?? '') ?? 0) / 100,
    );
  }

  @override
  List<Object?> get props => [dia, valor];
}

class ModalidadItem extends Equatable {
  final String nombre;
  final double porcentaje;
  final double valor;

  const ModalidadItem({
    required this.nombre,
    required this.porcentaje,
    required this.valor,
  });

  factory ModalidadItem.fromJson(Map<String, dynamic> json) {
    return ModalidadItem(
      nombre: json['modalidad'] as String? ?? '',
      porcentaje: double.tryParse(json['porcentaje']?.toString() ?? '') ?? 0,
      valor: (double.tryParse(json['montoRecaudo']?.toString() ?? '') ?? 0) / 100,
    );
  }

  @override
  List<Object?> get props => [nombre, porcentaje, valor];
}

class CobroEstadoItem extends Equatable {
  final String estado;
  final double porcentaje;
  final int cantidad;

  const CobroEstadoItem({
    required this.estado,
    required this.porcentaje,
    required this.cantidad,
  });

  factory CobroEstadoItem.fromJson(Map<String, dynamic> json) {
    return CobroEstadoItem(
      estado: json['estado'] as String? ?? '',
      porcentaje: (double.tryParse(json['porcentaje']?.toString() ?? '') ?? 0),
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '') ?? 0,
    );
  }

  @override
  List<Object?> get props => [estado, porcentaje, cantidad];
}

class ActividadItem extends Equatable {
  final String id;
  final String tipo;
  final String descripcion;
  final String usuario;
  final DateTime timestamp;
  final String hace;
  final Map<String, dynamic> metadata;

  const ActividadItem({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.usuario,
    required this.timestamp,
    required this.hace,
    this.metadata = const {},
  });

  factory ActividadItem.fromJson(Map<String, dynamic> json) {
    return ActividadItem(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      usuario: json['usuario'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      hace: json['hace'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [id, tipo, descripcion, usuario, timestamp, hace, metadata];
}

class CobroSemanaItem extends Equatable {
  final int semana;
  final int pagados;
  final int pendientes;
  final int mora;

  const CobroSemanaItem({
    required this.semana,
    required this.pagados,
    required this.pendientes,
    required this.mora,
  });

  factory CobroSemanaItem.fromJson(Map<String, dynamic> json) {
    return CobroSemanaItem(
      semana: int.tryParse(json['semana']?.toString() ?? '') ?? 1,
      pagados: int.tryParse(json['pagados']?.toString() ?? '') ?? 0,
      pendientes: int.tryParse(json['pendientes']?.toString() ?? '') ?? 0,
      mora: int.tryParse(json['mora']?.toString() ?? '') ?? 0,
    );
  }

  @override
  List<Object?> get props => [semana, pagados, pendientes, mora];
}

class MesHistorico extends Equatable {
  final int mes;
  final int anio;
  final double recaudo;
  final int pendientes;
  final double mora;

  const MesHistorico({
    required this.mes,
    required this.anio,
    required this.recaudo,
    required this.pendientes,
    required this.mora,
  });

  factory MesHistorico.fromJson(Map<String, dynamic> json) {
    return MesHistorico(
      mes: int.tryParse(json['mes']?.toString() ?? '') ?? 1,
      anio: int.tryParse(json['anio']?.toString() ?? '') ?? 2026,
      recaudo: (double.tryParse(json['recaudo']?.toString() ?? '') ?? 0) / 100,
      pendientes: int.tryParse(json['pendientes']?.toString() ?? '') ?? 0,
      mora: (double.tryParse(json['mora']?.toString() ?? '') ?? 0) / 100,
    );
  }

  @override
  List<Object?> get props => [mes, anio, recaudo, pendientes, mora];
}
