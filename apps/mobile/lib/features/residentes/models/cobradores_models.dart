import 'package:equatable/equatable.dart';

class CobradorResumen extends Equatable {
  final int totalCobradores;
  final int activos;
  final int inactivos;

  const CobradorResumen({
    required this.totalCobradores,
    required this.activos,
    required this.inactivos,
  });

  @override
  List<Object?> get props => [totalCobradores, activos, inactivos];
}

class CobradorItem extends Equatable {
  final String id;
  final String nombre;
  final String telefono;
  final String correo;
  final String? username;
  final String? usuarioId;
  final List<String> zonas;
  final bool activo;
  final int pagosRegistradosSemana;

  const CobradorItem({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.correo,
    this.username,
    this.usuarioId,
    required this.zonas,
    required this.activo,
    required this.pagosRegistradosSemana,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        telefono,
        correo,
        username,
        usuarioId,
        zonas,
        activo,
        pagosRegistradosSemana,
      ];
}
