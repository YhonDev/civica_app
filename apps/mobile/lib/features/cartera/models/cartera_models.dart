import 'package:equatable/equatable.dart';

/// Resumen general de la cartera (totales).
class CarteraResumen extends Equatable {
  final double totalPendiente;
  final double totalMora;
  final double totalPagado;
  
  final int cantidadPendientes;
  final int cantidadMora;
  final int cantidadPagados;

  const CarteraResumen({
    required this.totalPendiente,
    required this.totalMora,
    required this.totalPagado,
    required this.cantidadPendientes,
    required this.cantidadMora,
    required this.cantidadPagados,
  });

  @override
  List<Object?> get props => [
        totalPendiente,
        totalMora,
        totalPagado,
        cantidadPendientes,
        cantidadMora,
        cantidadPagados,
      ];
}

/// Representa un cobro o estado de cuenta de un propietario individual.
class CobroItem extends Equatable {
  final String id;
  final String residenteId;
  final String nombre;
  final String casa;
  final String manzana;
  final String etapa;
  final double monto;
  final double montoPagado;
  final double saldo;
  final String estado; // 'Pendiente', 'Mora', 'Pagado'
  final String modalidad; // 'Mensual', 'Quincenal', 'Semanal'
  final String fechaVencimiento;
  final String periodoInicio;
  final String periodoFin;

  const CobroItem({
    required this.id,
    required this.residenteId,
    required this.nombre,
    required this.casa,
    required this.manzana,
    required this.etapa,
    required this.monto,
    required this.montoPagado,
    required this.saldo,
    required this.estado,
    required this.modalidad,
    this.fechaVencimiento = '',
    this.periodoInicio = '',
    this.periodoFin = '',
  });

  factory CobroItem.fromJson(Map<String, dynamic> json) {
    final estadoDb = json['estado'];
    String estadoUi = 'Pendiente';
    if (estadoDb == 'PAGADA') estadoUi = 'Pagado';
    if (estadoDb == 'VENCIDA') estadoUi = 'Mora';

    final double monto = (json['monto'] ?? 0) / 100.0;
    final double pagado = (json['montoPagado'] ?? 0) / 100.0;
    final double saldo = monto - pagado;

    final propietario = json['residente'] as Map<String, dynamic>?;
    String nombre = propietario?['nombre'] ?? 'Desconocido';
    
    String casaNombre = 'Sin casa';
    String manzanaNombre = 'Sin manzana';
    String etapaNombre = 'Sin etapa';

    final tenencias = propietario?['tenencias'] as List<dynamic>? ?? [];
    if (tenencias.isNotEmpty) {
      final casa = tenencias.first['casa'] as Map<String, dynamic>?;
      if (casa != null) {
        casaNombre = casa['direccionInterna'] ?? 'Sin casa';
        final manzana = casa['manzana'] as Map<String, dynamic>?;
        if (manzana != null) {
          manzanaNombre = manzana['nombre'] ?? 'Sin manzana';
          final etapa = manzana['etapa'] as Map<String, dynamic>?;
          if (etapa != null) {
            etapaNombre = etapa['nombre'] ?? 'Sin etapa';
          }
        }
      }
    }

    final propId = propietario?['id'] as String? ?? '';
    final modalidad = propietario?['modalidadPago'] ?? 'Mensual';

    return CobroItem(
      id: json['id'].toString(),
      residenteId: propId,
      nombre: nombre,
      casa: casaNombre,
      manzana: manzanaNombre,
      etapa: etapaNombre,
      monto: monto,
      montoPagado: pagado,
      saldo: saldo,
      estado: estadoUi,
      modalidad: modalidad,
      fechaVencimiento: json['fechaVencimiento'] ?? '',
      periodoInicio: json['periodoInicio'] ?? '',
      periodoFin: json['periodoFin'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        residenteId,
        nombre,
        casa,
        manzana,
        etapa,
        monto,
        montoPagado,
        saldo,
        estado,
        modalidad,
        fechaVencimiento,
        periodoInicio,
        periodoFin,
      ];
}
