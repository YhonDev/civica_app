class MockData {
  // --- ESTRUCTURA DEL PROYECTO ---
  static const String nombreProyecto = 'Urbanización San Sebastián';

  static const List<String> etapas = [
    'Etapa 1',
  ];

  static const Map<String, List<String>> manzanasPorEtapa = {
    'Etapa 1': ['Manzana A'],
  };

  static const Map<String, List<String>> casasPorManzana = {
    'Manzana A': ['Casa 1', 'Casa 2', 'Casa 3', 'Casa 4', 'Casa 5'],
  };

  // --- USUARIOS ---
  static const List<Map<String, dynamic>> propietarios = [
    {
      'nombre': 'Juan Pérez',
      'etapa': 'Etapa 1',
      'manzana': 'Manzana A',
      'casa': 'Casa 1',
      'estado': 'Al día',
      'monto': '\$0',
    },
    {
      'nombre': 'Ana Gómez',
      'etapa': 'Etapa 1',
      'manzana': 'Manzana A',
      'casa': 'Casa 2',
      'estado': 'Mora',
      'monto': '\$120.000',
    },
    {
      'nombre': 'Carlos Ruiz',
      'etapa': 'Etapa 1',
      'manzana': 'Manzana A',
      'casa': 'Casa 3',
      'estado': 'Al día',
      'monto': '\$0',
    },
  ];

  static const List<Map<String, dynamic>> cobradores = [
    {
      'nombre': 'Pedro Cobrador',
      'etapasAsignadas': ['Etapa 1'],
      'casasAsignadas': 5,
      'estado': 'Activo',
    }
  ];
}
