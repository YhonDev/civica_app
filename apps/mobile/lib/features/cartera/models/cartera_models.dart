import 'package:equatable/equatable.dart';

import '../../../core/format/app_currency.dart';

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

  /// Genera un resumen dinámico a partir de una lista filtrada de [CobroItem].
  factory CarteraResumen.fromCobros(List<CobroItem> cobros) {
    double totalPendiente = 0;
    double totalMora = 0;
    double totalPagado = 0;
    int cantidadPendientes = 0;
    int cantidadMora = 0;
    int cantidadPagados = 0;

    for (final c in cobros) {
      if (c.isPaid) {
        cantidadPagados++;
        totalPagado += (c.montoPagado > 0 ? c.montoPagado : c.monto);
      } else if (c.isMora) {
        cantidadMora++;
        totalMora += (c.saldo > 0 ? c.saldo : c.monto);
        totalPagado += c.montoPagado;
      } else {
        cantidadPendientes++;
        totalPendiente += (c.saldo > 0 ? c.saldo : c.monto);
        totalPagado += c.montoPagado;
      }
    }

    return CarteraResumen(
      totalPendiente: totalPendiente,
      totalMora: totalMora,
      totalPagado: totalPagado,
      cantidadPendientes: cantidadPendientes,
      cantidadMora: cantidadMora,
      cantidadPagados: cantidadPagados,
    );
  }

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
  final String residenteId;
  final String nombre;
  final String casa;
  final String manzana;
  final String etapa;
  final double monto;
  final double montoPagado;
  final double saldo;
  final String estado; // 'Pendiente', 'Mora', 'Pagado'
  final String modalidad; // 'Mensual', 'Quincenal', 'Semanal'
  final String fechaVencimiento;
  final String periodoInicio;
  final String periodoFin;
  final String concepto;
  final String nroRecibo;
  final String cobradorNombre;
  final String fechaPago;
  final String metodoPago;
  final List<Map<String, dynamic>> cuotas;

  const CobroItem({
    required this.id,
    required this.residenteId,
    required this.nombre,
    required this.casa,
    required this.manzana,
    required this.etapa,
    required this.monto,
    required this.montoPagado,
    required this.saldo,
    required this.estado,
    required this.modalidad,
    this.fechaVencimiento = '',
    this.periodoInicio = '',
    this.periodoFin = '',
    this.concepto = 'Cuota de Vigilancia',
    this.nroRecibo = '',
    this.cobradorNombre = 'Administración',
    this.fechaPago = '',
    this.metodoPago = 'Efectivo',
    this.cuotas = const [],
  });

  bool get isPaid {
    final st = estado.toUpperCase();
    return st == 'PAGADO' || st == 'PAGADA';
  }

  bool get isMora {
    final st = estado.toUpperCase();
    return st == 'MORA' || st == 'VENCIDA';
  }

  bool get isPendiente => !isPaid && !isMora;

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  /// Retorna exclusivamente el nombre del mes (ej. "Septiembre")
  String get mesNombre {
    DateTime? date;
    if (periodoInicio.isNotEmpty) {
      date = DateTime.tryParse(periodoInicio);
    }
    date ??= DateTime.tryParse(fechaVencimiento);
    if (date != null && date.month >= 1 && date.month <= 12) {
      return _meses[date.month - 1];
    }
    return 'Mes Actual';
  }

  /// Retorna exclusivamente la cuota (ej. "Cuota 1" o "Cuota 3"), sin redundancia del mes
  String get cuotaNombre {
    // 1. Si el concepto contiene un patrón como "Cuota X", extraer únicamente "Cuota X"
    final cuotaMatch = RegExp(r'Cuota\s*\d+', caseSensitive: false).firstMatch(concepto);
    if (cuotaMatch != null) {
      final matchStr = cuotaMatch.group(0)!;
      final numStr = matchStr.replaceAll(RegExp(r'\D'), '');
      return 'Cuota $numStr';
    }

    // 2. Si el concepto tiene un separador "—" o "-" (ej. "Septiembre — Cuota 3")
    if (concepto.contains('—')) {
      final parts = concepto.split('—');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    } else if (concepto.contains('-')) {
      final parts = concepto.split('-');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }

    // 3. Si hay un concepto personalizado diferente a la vigilancia genérica
    if (concepto.isNotEmpty &&
        concepto != 'Cuota de Vigilancia' &&
        !concepto.toLowerCase().startsWith('cuota')) {
      return concepto;
    }

    // 4. Fallback calculado según el día de vencimiento
    if (fechaVencimiento.isNotEmpty) {
      final date = DateTime.tryParse(fechaVencimiento);
      if (date != null) {
        final day = date.day;
        int cuotaNum = 1;
        if (day > 21) {
          cuotaNum = 4;
        } else if (day > 14) {
          cuotaNum = 3;
        } else if (day > 7) {
          cuotaNum = 2;
        }
        return 'Cuota $cuotaNum';
      }
    }
    return 'Cuota 1';
  }

  /// Retorna exclusivamente la ubicación formateada (ej. "Manzana B · Casa 4")
  String get ubicacionNombre {
    final parts = <String>[];
    if (manzana.isNotEmpty && manzana != 'Manzana') {
      final mz = manzana.startsWith('Manzana') || manzana.startsWith('Mz')
          ? manzana
          : 'Manzana $manzana';
      parts.add(mz);
    }
    if (casa.isNotEmpty && casa != 'Inmueble') {
      final c = casa.startsWith('Casa') ? casa : 'Casa $casa';
      parts.add(c);
    }
    if (parts.isEmpty && etapa.isNotEmpty && etapa != 'Etapa') {
      final et = etapa.startsWith('Etapa') ? etapa : 'Etapa $etapa';
      parts.add(et);
    }
    if (parts.isEmpty && casa.isNotEmpty) parts.add(casa);
    return parts.join(' · ');
  }

  /// Retorna el título consolidado periodo-cuota (ej. "Septiembre — Cuota 1")
  String get tituloCuota {
    return '$mesNombre — $cuotaNombre';
  }

  /// Comparador para ordenar cobros para visitas y cobranza:
  /// 1. Fecha de vencimiento (ascendente, vencimiento más próximo primero)
  /// 2. Manzana (alfabético A -> Z)
  /// 3. Casa (numérico natural 1 -> 2 -> 10)
  /// 4. Cuota / Concepto
  static int comparePorVisitaYCobro(CobroItem a, CobroItem b) {
    // 1. Fecha de vencimiento (ascendente)
    DateTime? dateA;
    DateTime? dateB;
    if (a.fechaVencimiento.isNotEmpty) {
      dateA = DateTime.tryParse(a.fechaVencimiento);
    }
    if (b.fechaVencimiento.isNotEmpty) {
      dateB = DateTime.tryParse(b.fechaVencimiento);
    }

    if (dateA != null && dateB != null) {
      final cmpDate = dateA.compareTo(dateB);
      if (cmpDate != 0) return cmpDate;
    } else if (dateA != null) {
      return -1;
    } else if (dateB != null) {
      return 1;
    }

    // 2. Manzana alfabético (normalizado sin prefijo "Manzana" o "Mz")
    final mzA = a.manzana
        .replaceAll(RegExp(r'^(manzana|mz)\s*', caseSensitive: false), '')
        .trim()
        .toLowerCase();
    final mzB = b.manzana
        .replaceAll(RegExp(r'^(manzana|mz)\s*', caseSensitive: false), '')
        .trim()
        .toLowerCase();
    final cmpMz = mzA.compareTo(mzB);
    if (cmpMz != 0) return cmpMz;

    // 3. Casa (orden natural numérico si aplica)
    final numA = int.tryParse(a.casa.replaceAll(RegExp(r'\D'), ''));
    final numB = int.tryParse(b.casa.replaceAll(RegExp(r'\D'), ''));
    if (numA != null && numB != null) {
      final cmpCasa = numA.compareTo(numB);
      if (cmpCasa != 0) return cmpCasa;
    } else {
      final cmpCasa = a.casa.toLowerCase().compareTo(b.casa.toLowerCase());
      if (cmpCasa != 0) return cmpCasa;
    }

    // 4. Cuota / concepto
    return a.tituloCuota.compareTo(b.tituloCuota);
  }

  factory CobroItem.fromJson(Map<String, dynamic> json) {
    final estadoDb = (json['estado'] ?? '').toString().toUpperCase();
    String estadoUi = 'Pendiente';
    if (estadoDb == 'PAGADA' || estadoDb == 'PAGADO') estadoUi = 'Pagado';
    if (estadoDb == 'VENCIDA' || estadoDb == 'MORA') estadoUi = 'Mora';

    final double monto = AppCurrency.centsFromJson(json['monto']).toDouble();
    final double pagado = AppCurrency.centsFromJson(json['montoPagado']).toDouble();
    final double saldo = monto - pagado;

    final propietario = json['residente'] as Map<String, dynamic>?;
    String nombre = (propietario?['nombre'] as String?) ?? (json['residenteNombre'] as String?) ?? 'Residente';
    
    String casaNombre = (json['casaDireccion'] as String?) ?? 'Inmueble';
    String manzanaNombre = (json['manzanaNombre'] as String?) ?? 'Manzana';
    String etapaNombre = (json['etapaNombre'] as String?) ?? 'Etapa';

    // 1. Intentar obtener de relación directa `casa` o `casaActual`
    final casaObj = (json['casa'] as Map<String, dynamic>?) ?? (propietario?['casaActual'] as Map<String, dynamic>?);
    if (casaObj != null) {
      casaNombre = (casaObj['direccionInterna'] as String?) ?? (casaObj['nombre'] as String?) ?? casaNombre;
      final manzanaObj = casaObj['manzana'] as Map<String, dynamic>?;
      if (manzanaObj != null) {
        manzanaNombre = (manzanaObj['nombre'] as String?) ?? manzanaNombre;
        final etapaObj = manzanaObj['etapa'] as Map<String, dynamic>?;
        if (etapaObj != null) {
          etapaNombre = (etapaObj['nombre'] as String?) ?? etapaNombre;
        }
      }
    } else {
      // 2. Fallback a tenencias
      final tenencias = propietario?['tenencias'] as List<dynamic>? ?? [];
      if (tenencias.isNotEmpty) {
        final casa = tenencias.first['casa'] as Map<String, dynamic>?;
        if (casa != null) {
          casaNombre = (casa['direccionInterna'] as String?) ?? casaNombre;
          final manzana = casa['manzana'] as Map<String, dynamic>?;
          if (manzana != null) {
            manzanaNombre = (manzana['nombre'] as String?) ?? manzanaNombre;
            final etapa = manzana['etapa'] as Map<String, dynamic>?;
            if (etapa != null) {
              etapaNombre = (etapa['nombre'] as String?) ?? etapaNombre;
            }
          }
        }
      }
    }

    final propId = propietario?['id'] as String? ?? '';
    final modalidad = propietario?['modalidadPago'] ?? 'Mensual';

    return CobroItem(
      id: json['id'].toString(),
      residenteId: propId,
      nombre: nombre,
      casa: casaNombre,
      manzana: manzanaNombre,
      etapa: etapaNombre,
      monto: monto,
      montoPagado: pagado,
      saldo: saldo,
      estado: estadoUi,
      modalidad: modalidad,
      fechaVencimiento: json['fechaVencimiento'] ?? '',
      periodoInicio: json['periodoInicio'] ?? '',
      periodoFin: json['periodoFin'] ?? '',
      concepto: json['concepto'] as String? ?? 'Cuota de Vigilancia',
      nroRecibo: json['nroRecibo'] as String? ?? '',
      cobradorNombre: json['cobradorNombre'] as String? ?? 'Administración',
      fechaPago: json['fechaPago'] as String? ?? '',
      metodoPago: json['metodoPago'] as String? ?? 'Efectivo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residenteId': residenteId,
      'residenteNombre': nombre,
      'casaDireccion': casa,
      'manzanaNombre': manzana,
      'etapaNombre': etapa,
      'monto': monto,
      'montoPagado': montoPagado,
      'saldo': saldo,
      'estado': estado,
      'modalidad': modalidad,
      'fechaVencimiento': fechaVencimiento,
      'periodoInicio': periodoInicio,
      'periodoFin': periodoFin,
      'concepto': concepto,
      'nroRecibo': nroRecibo,
      'cobradorNombre': cobradorNombre,
      'fechaPago': fechaPago,
      'metodoPago': metodoPago,
    };
  }

  @override
  List<Object?> get props => [
        id,
        residenteId,
        nombre,
        casa,
        manzana,
        etapa,
        monto,
        montoPagado,
        saldo,
        estado,
        modalidad,
        fechaVencimiento,
        periodoInicio,
        periodoFin,
        nroRecibo,
        fechaPago,
      ];
}
