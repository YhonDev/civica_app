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
  final String nombre;
  final String casa;
  final String etapa;
  final double saldo;
  final String estado; // 'Pendiente', 'Mora', 'Pagado'
  final String modalidad; // 'Mensual', 'Quincenal', 'Semanal'

  const CobroItem({
    required this.id,
    required this.nombre,
    required this.casa,
    required this.etapa,
    required this.saldo,
    required this.estado,
    required this.modalidad,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        casa,
        etapa,
        saldo,
        estado,
        modalidad,
      ];
}
