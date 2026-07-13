import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class ComunidadRepository {
  final ApiClient _api = ApiClient.instance;
  
  static const String currentTenantId = 'aeb25e74-8b70-43c8-9789-48b337fd6093';

  // ════════════════════════════════════════════════════════════
  // PROYECTOS (CONJUNTOS)
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getProyectos() async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      return (response.data as List<dynamic>).map((p) {
        int totalEtapas = 0;
        int totalManzanas = 0;
        int totalCasas = 0;

        final etapas = p['etapas'] as List<dynamic>? ?? [];
        totalEtapas = etapas.length;

        for (var e in etapas) {
          final manzanas = e['manzanas'] as List<dynamic>? ?? [];
          totalManzanas += manzanas.length;
          for (var m in manzanas) {
            final casas = m['casas'] as List<dynamic>? ?? [];
            totalCasas += casas.length;
          }
        }

        return {
          'id': p['id'],
          'nombre': p['nombre'],
          'estado': 'Activo',
          'etapas': totalEtapas,
          'manzanas': totalManzanas,
          'casas': totalCasas,
        };
      }).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar proyectos: $e');
    }
  }


  Future<Map<String, dynamic>> createProyecto(String nombre) async {
    try {
      final response = await _api.post('/conjuntos', data: {
        'nombre': nombre,
        'tenantId': currentTenantId,
      });
      return {
        'id': response.data['id'],
        'nombre': response.data['nombre'],
        'estado': 'Activo',
      };
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear proyecto: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ETAPAS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getEtapasPorProyecto(String proyectoId) async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      final proyectos = response.data as List<dynamic>;
      final proyecto = proyectos.firstWhere((p) => p['id'] == proyectoId, orElse: () => null);
      if (proyecto == null) return [];
      
      return (proyecto['etapas'] as List<dynamic>).map((e) => {
        'id': e['id'],
        'nombre': e['nombre'],
      }).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar etapas: $e');
    }
  }

  Future<Map<String, dynamic>> createEtapa(String nombre, String proyectoId) async {
    try {
      final response = await _api.post('/conjuntos/$proyectoId/etapas', data: {
        'nombre': nombre,
      });
      return response.data;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear etapa: $e');
    }
  }
  
  Future<void> deleteEtapa(String id) async {
    try {
      await _api.delete('/conjuntos/etapas/$id');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al eliminar etapa: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // MANZANAS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getManzanasPorEtapa(String etapaId) async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      final proyectos = response.data as List<dynamic>;
      for (final p in proyectos) {
        for (final e in p['etapas']) {
          if (e['id'] == etapaId) {
            return (e['manzanas'] as List<dynamic>).map((m) => {
              'id': m['id'],
              'nombre': m['nombre'],
            }).toList();
          }
        }
      }
      return [];
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar manzanas: $e');
    }
  }

  // Obtiene todas las etapas con sus respectivas manzanas (para la pantalla de manzanas)
  Future<List<Map<String, dynamic>>> getEtapasConManzanas() async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      final proyectos = response.data as List<dynamic>;
      if (proyectos.isEmpty) return [];
      
      final etapas = proyectos.first['etapas'] as List<dynamic>;
      return etapas.map((e) => {
        'id': e['id'],
        'nombre': e['nombre'],
        'manzanas': (e['manzanas'] as List<dynamic>).map((m) => {
          'id': m['id'],
          'nombre': m['nombre'],
        }).toList(),
      }).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar árbol de manzanas: $e');
    }
  }

  // Obtiene todo el árbol: Etapas -> Manzanas -> Casas (Solo disponibles + includeCasaId)
  Future<List<Map<String, dynamic>>> getArbolCompleto({String? includeCasaId}) async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      final proyectos = response.data as List<dynamic>;
      if (proyectos.isEmpty) return [];
      
      // Obtener casas ocupadas a través de propietarios activos
      final responseProps = await _api.get('/propietarios', queryParameters: {
        'tenantId': currentTenantId,
      });
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

      final etapas = proyectos.first['etapas'] as List<dynamic>;
      return etapas.map((e) => {
        'id': e['id'],
        'nombre': e['nombre'],
        'manzanas': (e['manzanas'] as List<dynamic>? ?? []).map((m) {
          // Filtrar las casas ocupadas, pero mantener la casa actual si se está editando
          final casasList = (m['casas'] as List<dynamic>? ?? [])
              .where((c) {
                final id = c['id'].toString();
                return id == includeCasaId || !ocupadasSet.contains(id);
              })
              .map((c) => {
                'id': c['id'],
                'nombre': c['direccionInterna'] ?? '',
              }).toList();
          return {
            'id': m['id'],
            'nombre': m['nombre'],
            'casas': casasList,
          };
        }).toList(),
      }).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar árbol completo: $e');
    }
  }

  Future<Map<String, dynamic>> createManzana(String nombre, String etapaId) async {
    try {
      final response = await _api.post('/conjuntos/etapas/$etapaId/manzanas', data: {
        'nombre': nombre,
      });
      return response.data;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear manzana: $e');
    }
  }
  
  Future<void> deleteManzana(String id) async {
    try {
      await _api.delete('/conjuntos/manzanas/$id');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al eliminar manzana: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // CASAS (LOTES)
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getCasasPorManzana(String manzanaId) async {
    try {
      final response = await _api.get('/conjuntos', queryParameters: {
        'tenantId': currentTenantId,
      });
      final proyectos = response.data as List<dynamic>;
      for (final p in proyectos) {
        for (final e in p['etapas']) {
          for (final m in e['manzanas']) {
            if (m['id'] == manzanaId) {
              return (m['casas'] as List<dynamic>).map((c) => {
                'id': c['id'],
                'direccion_interna': c['direccionInterna'],
              }).toList();
            }
          }
        }
      }
      return [];
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar casas: $e');
    }
  }

  Future<Map<String, dynamic>> createCasa(String nombre, String manzanaId) async {
    try {
      final response = await _api.post('/conjuntos/manzanas/$manzanaId/casas', data: {
        'direccionInterna': nombre,
      });
      return {
        'id': response.data['id'],
        'direccion_interna': response.data['direccionInterna'],
      };
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear casa: $e');
    }
  }
  
  Future<void> deleteCasa(String id) async {
    try {
      await _api.delete('/conjuntos/casas/$id');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al eliminar casa: $e');
    }
  }
}
