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
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final estadoCobrosMap = json['estadoCobros'] as Map<String, dynamic>? ?? {};

    return DashboardData(
      mes: int.tryParse(json['mes']?.toString() ?? '') ?? 0,
      anio: int.tryParse(json['anio']?.toString() ?? '') ?? 0,
      recaudoMes: (double.tryParse(resumen['recaudoTotal']?.toString() ?? '') ?? 0) / 100,
      metaMensual: (double.tryParse(resumen['metaMensual']?.toString() ?? '') ?? 0) / 100,
      pagaron: int.tryParse(resumen['pagaron']?.toString() ?? '') ?? 0,
      pendientes: int.tryParse(resumen['pendientes']?.toString() ?? '') ?? 0,
      mora: (double.tryParse(resumen['moraTotal']?.toString() ?? '') ?? 0) / 100,
      porcentaje: double.tryParse(resumen['porcentajeMeta']?.toString() ?? '') ?? 0,
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
          porcentaje: double.tryParse(estadoCobrosMap['pagados']?.toString() ?? '') ?? 0,
          cantidad: 0,
        ),
        CobroEstadoItem(
          estado: 'Pendientes',
          porcentaje: double.tryParse(estadoCobrosMap['pendientes']?.toString() ?? '') ?? 0,
          cantidad: 0,
        ),
        CobroEstadoItem(
          estado: 'Revisión',
          porcentaje: double.tryParse(estadoCobrosMap['revision']?.toString() ?? '') ?? 0,
          cantidad: 0,
        ),
      ],
      actividadReciente: (json['actividad'] as List<dynamic>?)
              ?.map((e) => ActividadItem.fromJson(e as Map<String, dynamic>))
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
      nombre: json['frecuencia'] as String? ?? '',
      porcentaje: double.tryParse(json['porcentaje']?.toString() ?? '') ?? 0,
      valor: 0, // backend no envía recaudo por modalidad de forma plana aún
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
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
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

  const ActividadItem({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.usuario,
    required this.timestamp,
    required this.hace,
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
    );
  }

  @override
  List<Object?> get props => [id, tipo, descripcion, usuario, timestamp, hace];
}
