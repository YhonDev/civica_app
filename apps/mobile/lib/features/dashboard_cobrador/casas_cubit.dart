import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';

// ════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════

class CasaExplorer extends Equatable {
  final String id;
  final String direccion;
  final String residenteNombre;
  final String residenteTelefono;
  final String estado;  // AL_DIA, PENDIENTE, PARCIAL, VENCIDA
  final int saldo;

  const CasaExplorer({
    required this.id,
    required this.direccion,
    required this.residenteNombre,
    required this.residenteTelefono,
    required this.estado,
    required this.saldo,
  });

  factory CasaExplorer.fromJson(Map<String, dynamic> json) {
    return CasaExplorer(
      id: json['id'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      residenteNombre: json['residenteNombre'] as String? ?? 'Sin residente',
      residenteTelefono: json['residenteTelefono'] as String? ?? '',
      estado: json['estado'] as String? ?? 'AL_DIA',
      saldo: json['saldo'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, direccion, residenteNombre, estado, saldo];
}

class ManzanaExplorer extends Equatable {
  final String id;
  final String nombre;
  final List<CasaExplorer> casas;

  const ManzanaExplorer({required this.id, required this.nombre, required this.casas});

  factory ManzanaExplorer.fromJson(Map<String, dynamic> json) {
    return ManzanaExplorer(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      casas: (json['casas'] as List? ?? [])
          .map((c) => CasaExplorer.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, nombre, casas];
}

class EtapaExplorer extends Equatable {
  final String id;
  final String nombre;
  final List<ManzanaExplorer> manzanas;

  const EtapaExplorer({required this.id, required this.nombre, required this.manzanas});

  factory EtapaExplorer.fromJson(Map<String, dynamic> json) {
    return EtapaExplorer(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      manzanas: (json['manzanas'] as List? ?? [])
          .map((m) => ManzanaExplorer.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, nombre, manzanas];
}

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

abstract class CasasState extends Equatable {
  const CasasState();
  @override
  List<Object?> get props => [];
}

class ViviendasInitial extends CasasState {
  const ViviendasInitial();
}

class ViviendasLoading extends CasasState {
  const ViviendasLoading();
}

class ViviendasLoaded extends CasasState {
  final List<EtapaExplorer> etapas;

  const ViviendasLoaded(this.etapas);
  @override
  List<Object?> get props => [etapas];
}

class ViviendasError extends CasasState {
  final String message;
  const ViviendasError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class CasasCubit extends Cubit<CasasState> {
  final ApiClient _api;

  CasasCubit({ApiClient? api})
      : _api = api ?? ApiClient.instance,
        super(const ViviendasInitial());

  Future<void> loadViviendas() async {
    emit(const ViviendasLoading());
    try {
      final response = await _api.get('/dashboard/cobrador/viviendas');
      final data = response.data as Map<String, dynamic>;
      final etapas = (data['etapas'] as List? ?? [])
          .map((e) => EtapaExplorer.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(ViviendasLoaded(etapas));
    } catch (e) {
      emit(ViviendasError('Error al cargar casas: $e'));
    }
  }

  Future<void> refresh() async {
    await loadViviendas();
  }
}
