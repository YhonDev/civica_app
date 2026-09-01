import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';

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
  final List<Map<String, dynamic>> solicitudes;

  const ViviendasLoaded(this.etapas, {this.solicitudes = const []});
  @override
  List<Object?> get props => [etapas, solicitudes];
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

  Future<void> loadViviendas({bool silent = false, bool forceFresh = true}) async {
    if (forceFresh) {
      LocalCacheRepository.instance.invalidate('cobrador:viviendas');
    }

    if (!silent && LocalCacheRepository.instance.getCached('cobrador:viviendas') == null) {
      emit(const ViviendasLoading());
    }

    await LocalCacheRepository.instance.executeSWR<Map<String, dynamic>>(
      key: 'cobrador:viviendas',
      fetcher: () async {
        final response = await _api.get('/dashboard/cobrador/viviendas');
        return response.data as Map<String, dynamic>;
      },
      onData: (data, isStale) {
        final etapas = (data['etapas'] as List? ?? [])
            .map((e) => EtapaExplorer.fromJson(e as Map<String, dynamic>))
            .toList();
        final solicitudes = List<Map<String, dynamic>>.from(data['solicitudes'] as List? ?? []);
        emit(ViviendasLoaded(etapas, solicitudes: solicitudes));
      },
      onError: (e) {
        if (!silent && LocalCacheRepository.instance.getCached('cobrador:viviendas') == null) {
          emit(ViviendasError('Error al cargar casas: $e'));
        }
      },
    );
  }

  void cambiarEstadoSolicitud(String solicitudId, String nuevoEstado) {
    if (state is! ViviendasLoaded) return;
    final current = state as ViviendasLoaded;
    final updatedSolicitudes = current.solicitudes.map((s) {
      if (s['id'] == solicitudId) {
        final map = Map<String, dynamic>.from(s);
        map['estado'] = nuevoEstado;
        return map;
      }
      return s;
    }).toList();

    emit(ViviendasLoaded(current.etapas, solicitudes: updatedSolicitudes));
  }

  Future<void> refresh() async {
    await loadViviendas(silent: false, forceFresh: true);
  }
}
