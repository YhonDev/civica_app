import 'package:equatable/equatable.dart';

class ResidenteResumen extends Equatable {
  final int totalPropiedades;
  final int ocupadas;
  final int vacantes;

  const ResidenteResumen({
    required this.totalPropiedades,
    required this.ocupadas,
    required this.vacantes,
  });

  @override
  List<Object?> get props => [totalPropiedades, ocupadas, vacantes];
}

class ResidenteItem extends Equatable {
  final String id;
  final String nombre;
  final String telefono;
  final String casa;
  final String etapa;
  final String? casaId;
  final String? manzanaId;
  final String? etapaId;
  final String? email;
  final String? username;
  final String? usuarioId;
  final String modalidadPago;
  final String estadoFinanciero; // 'Al Día', 'Mora', 'Pendiente'
  final double saldoPendiente;

  const ResidenteItem({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.casa,
    required this.etapa,
    this.casaId,
    this.manzanaId,
    this.etapaId,
    this.email,
    this.username,
    this.usuarioId,
    required this.modalidadPago,
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
        casaId,
        manzanaId,
        etapaId,
        email,
        username,
        usuarioId,
        modalidadPago,
        estadoFinanciero,
        saldoPendiente,
      ];
}
