import 'package:equatable/equatable.dart';

class PropietarioResumen extends Equatable {
  final int totalPropiedades;
  final int ocupadas;
  final int vacantes;

  const PropietarioResumen({
    required this.totalPropiedades,
    required this.ocupadas,
    required this.vacantes,
  });

  @override
  List<Object?> get props => [totalPropiedades, ocupadas, vacantes];
}

class PropietarioItem extends Equatable {
  final String id;
  final String nombre;
  final String telefono;
  final String casa;
  final String etapa;
  final String estadoFinanciero; // 'Al Día', 'Mora', 'Pendiente'
  final double saldoPendiente;

  const PropietarioItem({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.casa,
    required this.etapa,
    required this.estadoFinanciero,
    required this.saldoPendiente,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        telefono,
        casa,
        etapa,
        estadoFinanciero,
        saldoPendiente,
      ];
}
