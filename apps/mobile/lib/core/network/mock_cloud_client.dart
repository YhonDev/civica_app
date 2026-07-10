import 'dart:math';

class MockCloudClient {
  static final MockCloudClient _instance = MockCloudClient._internal();
  factory MockCloudClient() => _instance;
  MockCloudClient._internal();

  // In-memory "Cloud" database (State 0 at startup)
  final List<Map<String, dynamic>> _proyectos = [];
  final List<Map<String, dynamic>> _etapas = [];
  final List<Map<String, dynamic>> _manzanas = [];
  final List<Map<String, dynamic>> _casas = [];

  // Helper to simulate network latency
  Future<void> _simulateNetworkDelay() async {
    final random = Random();
    await Future.delayed(Duration(milliseconds: 300 + random.nextInt(500)));
  }

  // Helper to generate UUIDs
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  // ════════════════════════════════════════════════════════════
  // PROYECTOS (URBANIZACIONES)
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getProyectos() async {
    await _simulateNetworkDelay();
    // Return a copy to simulate API parsing
    return List.from(_proyectos);
  }

  Future<Map<String, dynamic>> getProyecto(String id) async {
    await _simulateNetworkDelay();
    return _proyectos.firstWhere((p) => p['id'] == id);
  }

  Future<Map<String, dynamic>> createProyecto(String nombre) async {
    await _simulateNetworkDelay();
    final newProject = {
      'id': _generateId(),
      'nombre': nombre,
      'estado': 'Activo',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _proyectos.add(newProject);
    return newProject;
  }

  // ════════════════════════════════════════════════════════════
  // ETAPAS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getEtapasPorProyecto(String proyectoId) async {
    await _simulateNetworkDelay();
    return _etapas.where((e) => e['proyectoId'] == proyectoId).toList();
  }

  Future<Map<String, dynamic>> createEtapa(String nombre, String proyectoId) async {
    await _simulateNetworkDelay();
    final newEtapa = {
      'id': _generateId(),
      'nombre': nombre,
      'proyectoId': proyectoId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _etapas.add(newEtapa);
    return newEtapa;
  }

  // ════════════════════════════════════════════════════════════
  // MANZANAS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getManzanasPorEtapa(String etapaId) async {
    await _simulateNetworkDelay();
    return _manzanas.where((m) => m['etapaId'] == etapaId).toList();
  }

  Future<Map<String, dynamic>> createManzana(String nombre, String etapaId) async {
    await _simulateNetworkDelay();
    final newManzana = {
      'id': _generateId(),
      'nombre': nombre,
      'etapaId': etapaId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _manzanas.add(newManzana);
    return newManzana;
  }

  // ════════════════════════════════════════════════════════════
  // CASAS (LOTES)
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getCasasPorManzana(String manzanaId) async {
    await _simulateNetworkDelay();
    return _casas.where((c) => c['manzanaId'] == manzanaId).toList();
  }

  Future<Map<String, dynamic>> createCasa(String nombre, String manzanaId) async {
    await _simulateNetworkDelay();
    final newCasa = {
      'id': _generateId(),
      'nombre': nombre,
      'manzanaId': manzanaId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _casas.add(newCasa);
    return newCasa;
  }
}
