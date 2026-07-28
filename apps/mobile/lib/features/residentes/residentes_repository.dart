import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import 'models/residentes_models.dart';

class ResidentesRepository {
  final ApiClient _api;

  ResidentesRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  /// Obtiene el resumen de la comunidad.
  Future<ResidenteResumen> getResumen() async {
    try {
      // 1. Obtener todas las casas a través de conjuntos
      int totalCasas = 0;
      final responseConjuntos = await _api.get('/proyectos');
      final proyectos = responseConjuntos.data as List<dynamic>;
      
      for (var p in proyectos) {
        for (var e in (p['etapas'] ?? [])) {
          for (var m in (e['manzanas'] ?? [])) {
            totalCasas += (m['casas'] as List).length;
          }
        }
      }

      // 2. Obtener casas ocupadas a través de propietarios activos
      final responseProps = await _api.get('/residentes');
      final propietarios = responseProps.data as List<dynamic>;
      
      final ocupadasSet = <String>{};
      for (var p in propietarios) {
        final tenencias = p['tenencias'] as List<dynamic>? ?? [];
        for (var t in tenencias) {
          if (t['casaId'] != null) {
            ocupadasSet.add(t['casaId'].toString());
          }
        }
      }

      final ocupadas = ocupadasSet.length;

      return ResidenteResumen(
        totalPropiedades: totalCasas,
        ocupadas: ocupadas,
        vacantes: totalCasas - ocupadas,
      );
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar resumen: $e');
    }
  }

  /// Obtiene la lista completa de propietarios en la comunidad.
  Future<List<ResidenteItem>> getPropietarios() async {
    try {
      final response = await _api.get('/residentes');
      final List<dynamic> data = response.data;
      
      final List<ResidenteItem> propietarios = [];
      
      for (var p in data) {
        double saldo = 0.0;
        bool enMora = false;
        
        final cuotas = p['cuotas'] as List<dynamic>? ?? [];
        for (var cuota in cuotas) {
          if (cuota['estado'] == 'VENCIDA') {
            enMora = true;
            saldo += ((cuota['monto'] ?? 0) - (cuota['montoPagado'] ?? 0)) / 100.0;
          } else if (cuota['estado'] == 'PENDIENTE') {
            saldo += ((cuota['monto'] ?? 0) - (cuota['montoPagado'] ?? 0)) / 100.0;
          }
        }

        String estadoFinanciero = enMora ? 'Mora' : 'Al Día';
        if (saldo == 0) estadoFinanciero = 'Al Día';

        String casaNombre = 'Sin casa';
        String etapaNombre = 'Sin etapa';
        String manzanaNombre = 'Sin manzana';
        String? casaId;
        String? manzanaId;
        String? etapaId;
        String? email = p['email'];
        String? username = p['username'];
        String? usuarioId = p['usuarioId']?.toString();
        String modalidadPago = p['modalidad_pago'] ?? p['modalidadPago'] ?? 'MENSUAL';
        
        final tenencias = p['tenencias'] as List<dynamic>? ?? [];
        if (tenencias.isNotEmpty) {
          final tenencia = tenencias.first;
          final casa = tenencia['casa'];
          if (casa != null) {
            casaNombre = casa['direccionInterna'] ?? 'Sin casa';
            casaId = casa['id'];
            final manzana = casa['manzana'];
            if (manzana != null) {
              manzanaNombre = manzana['nombre'] ?? 'Sin manzana';
              manzanaId = manzana['id'];
              final etapa = manzana['etapa'];
              if (etapa != null) {
                etapaNombre = etapa['nombre'] ?? 'Sin etapa';
                etapaId = etapa['id'];
              }
            }
          }
        }

        propietarios.add(
          ResidenteItem(
            id: p['id'].toString(),
            nombre: p['nombre'] ?? '',
            telefono: p['telefono'] ?? '',
            email: email,
            username: username,
            usuarioId: usuarioId,
            casa: '$manzanaNombre - $casaNombre',
            etapa: etapaNombre,
            casaId: casaId?.toString(),
            manzanaId: manzanaId?.toString(),
            etapaId: etapaId?.toString(),
            modalidadPago: modalidadPago,
            estadoFinanciero: estadoFinanciero,
            saldoPendiente: saldo,
          ),
        );
      }

      // Invertir la lista para que los más nuevos salgan arriba
      return propietarios.reversed.toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar propietarios: $e');
    }
  }

  /// Crea un nuevo propietario en el backend.
  /// Retorna el response completo (incluye credenciales generadas).
  Future<Map<String, dynamic>> createPropietario({
    required String nombre,
    required String telefono,
    String? email,
    String? casaId,
    String? fechaInicio,
    String modalidadPago = 'MENSUAL',
  }) async {
    try {
      final payload = {
        'nombre': nombre,
        'telefono': telefono,
        'modalidadPago': modalidadPago,
      };

      if (email != null && email.isNotEmpty) {
        payload['email'] = email;
      }
      if (casaId != null && casaId.isNotEmpty) {
        payload['casaId'] = casaId;
      }
      if (fechaInicio != null && fechaInicio.isNotEmpty) {
        payload['fechaInicio'] = fechaInicio;
      }

      final response = await _api.post<Map<String, dynamic>>('/residentes', data: payload);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear propietario: $e');
    }
  }

  Future<bool> deletePropietario(String id) async {
    try {
      await _api.delete('/residentes/$id');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar propietario: $e');
      }
      return false;
    }
  }

  Future<bool> updatePropietario(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('/residentes/$id', data: data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar propietario: $e');
      }
      return false;
    }
  }

  Future<bool> deleteCuota(String cobroId) async {
    try {
      await _api.delete('/cobros/$cobroId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error al eliminar cuota: $e');
      return false;
    }
  }

  Future<bool> deletePago(String pagoId) async {
    try {
      await _api.delete('/pagos/$pagoId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error al eliminar pago: $e');
      return false;
    }
  }

  /// Regenera la password de un usuario (residente o cobrador). Solo admin.
  /// Retorna { username, password } con las nuevas credenciales.
  Future<Map<String, String>> resetPassword({
    String? residenteId,
    String? usuarioId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (residenteId != null) payload['residenteId'] = residenteId;
      if (usuarioId != null) payload['usuarioId'] = usuarioId;

      final response = await _api.post('/auth/reset-password', data: payload);
      final data = response.data as Map<String, dynamic>;
      return {
        'username': data['username']?.toString() ?? '',
        'password': data['password']?.toString() ?? '',
      };
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al resetear password: $e');
    }
  }
}
