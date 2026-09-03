// Value Objects compartidos del dominio
// Inmutables, se comparan por valor.

export class TenantId {
  constructor(public readonly value: string) {
    if (!value || value.trim().length === 0) {
      throw new Error('TenantId no puede estar vacío');
    }
  }

  equals(other: TenantId): boolean {
    return this.value === other.value;
  }
}

export class Email {
  private static readonly PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  constructor(public readonly value: string) {
    if (!Email.PATTERN.test(value)) {
      throw new Error(`Email inválido: ${value}`);
    }
  }

  equals(other: Email): boolean {
    return this.value === other.value;
  }
}

export class Telefono {
  constructor(public readonly value: string) {
    const digits = value.replace(/\D/g, '');
    if (digits.length < 7 || digits.length > 15) {
      throw new Error(
        `Teléfono inválido: ${value}. Debe tener entre 7 y 15 dígitos.`,
      );
    }
  }

  equals(other: Telefono): boolean {
    return this.value === other.value;
  }
}

export class Nombre {
  constructor(public readonly value: string) {
    if (!value || value.trim().length < 2) {
      throw new Error('Nombre debe tener al menos 2 caracteres');
    }
  }

  equals(other: Nombre): boolean {
    return this.value === other.value;
  }
}

export class DireccionInterna {
  constructor(public readonly value: string) {
    if (!value || value.trim().length === 0) {
      throw new Error('Dirección interna no puede estar vacía');
    }
  }

  equals(other: DireccionInterna): boolean {
    return this.value === other.value;
  }
}

// ── Ledger VOs ──────────────────────────────────────────

export type ModalidadRecaudo = 'SEMANAL' | 'QUINCENAL' | 'MENSUAL';

/** @deprecated Usar ModalidadRecaudo. Se mantiene temporalmente para compatibilidad. */
export type Frecuencia = ModalidadRecaudo;

/**
 * Alias semántico para ModalidadRecaudo.
 * Usar en contextos donde se hable de 'modalidad' del plan/tarifa.
 */
export type Modalidad = ModalidadRecaudo;

/** Valor inicial para seeds — en runtime siempre consultar tarifas vigentes en BD. */
export const CUOTA_MENSUAL_CIVICA_DEFAULT_PESOS = 40_000;
export const CUOTA_MENSUAL_CIVICA_DEFAULT_CENTAVOS =
  CUOTA_MENSUAL_CIVICA_DEFAULT_PESOS * 100;

/** @deprecated Usar CUOTA_MENSUAL_CIVICA_DEFAULT_PESOS (solo seeds). */
export const CUOTA_MENSUAL_CIVICA_PESOS = CUOTA_MENSUAL_CIVICA_DEFAULT_PESOS;

/** @deprecated Usar CUOTA_MENSUAL_CIVICA_DEFAULT_CENTAVOS (solo seeds). */
export const CUOTA_MENSUAL_CIVICA_CENTAVOS =
  CUOTA_MENSUAL_CIVICA_DEFAULT_CENTAVOS;

/** Pagos por mes según la modalidad de recaudo del residente. */
export function pagosPorMes(modalidad: ModalidadRecaudo): number {
  switch (modalidad) {
    case 'SEMANAL':
      return 4;
    case 'QUINCENAL':
      return 2;
    case 'MENSUAL':
      return 1;
  }
}

/**
 * Convierte un monto de cualquier modalidad al equivalente mensual.
 * Ej: $10.000 semanal → $40.000 mensual.
 */
export function montoMensualDesde(
  modalidad: ModalidadRecaudo,
  montoCentavos: number,
): number {
  return montoCentavos * pagosPorMes(modalidad);
}

/**
 * Calcula los montos de tarifa para las 3 modalidades a partir de la cuota mensual.
 * La cuota cívica mensual se divide: /4 semanal, /2 quincenal, /1 mensual.
 */
export function tarifasDerivadas(
  montoMensualCentavos: number,
): Record<ModalidadRecaudo, number> {
  return {
    MENSUAL: montoMensualCentavos,
    QUINCENAL: Math.round(montoMensualCentavos / 2),
    SEMANAL: Math.round(montoMensualCentavos / 4),
  };
}

/**
 * Monto de cada abono parcial según la modalidad de recaudo.
 * La cuota mensual completa se divide en 4, 2 o 1 pagos.
 */
export function calcularMontoParcial(
  montoMensualCentavos: number,
  modalidad: ModalidadRecaudo,
): Money {
  const divisor = pagosPorMes(modalidad);
  return Money.ofCOP(Math.round(montoMensualCentavos / divisor));
}

/** @deprecated Usar calcularMontoParcial — la cuota almacena el monto mensual completo. */
export function calcularMontoCuota(
  montoMensualCentavos: number,
  modalidad: ModalidadRecaudo,
): Money {
  return calcularMontoParcial(montoMensualCentavos, modalidad);
}

export class Money {
  constructor(
    public readonly amount: number, // en centavos (integer)
    public readonly currency: 'COP' = 'COP',
  ) {
    if (typeof amount !== 'number' || isNaN(amount)) {
      throw new Error('Money amount debe ser un número válido');
    }
    if (!Number.isInteger(amount)) {
      throw new Error('COP no acepta decimales — usa centavos');
    }
  }

  static ofCOP(pesos: number): Money {
    if (pesos < 0) throw new Error('Money no puede ser negativo');
    return new Money(pesos, 'COP');
  }

  get pesos(): number {
    return this.amount;
  }

  add(other: Money): Money {
    if (this.currency !== other.currency)
      throw new Error('No se pueden sumar monedas distintas');
    return new Money(this.amount + other.amount, this.currency);
  }

  subtract(other: Money): Money {
    if (this.currency !== other.currency)
      throw new Error('No se pueden restar monedas distintas');
    const result = this.amount - other.amount;
    if (result < 0) throw new Error('Saldo no puede ser negativo');
    return new Money(result, this.currency);
  }

  isZero(): boolean {
    return this.amount === 0;
  }

  isGreaterThan(other: Money): boolean {
    return this.amount > other.amount;
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}

/**
 * Estados posibles de un cobro (antes EstadoCuota).
 */
export type EstadoCobro =
  'PENDIENTE' | 'PARCIAL' | 'PAGADA' | 'VENCIDA' | 'EN_REVISION' | 'ANULADO';

/** @deprecated Usar EstadoCobro */
export type EstadoCuota = EstadoCobro;

export type SyncStatus = 'PENDIENTE_SYNC' | 'SYNC_OK' | 'CONFLICTO';

/** Margen en días para alinear vencimiento al sábado más cercano a la quincena. */
const MARGEN_QUINCENA_DIAS = 4;

function toLocalDate(year: number, month: number, day: number): Date {
  return new Date(year, month, day);
}

function parseLocalDate(dateStr: string): Date {
  const [y, m, d] = dateStr.split('-').map(Number);
  return toLocalDate(y, m - 1, d);
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function normalizeDate(d: Date): Date {
  return toLocalDate(d.getFullYear(), d.getMonth(), d.getDate());
}

export class Periodo {
  constructor(
    public readonly inicio: Date,
    public readonly fin: Date,
    public readonly vencimiento: Date,
  ) {}

  get inicioStr(): string {
    return formatDate(this.inicio);
  }

  get finStr(): string {
    return formatDate(this.fin);
  }

  get vencimientoStr(): string {
    return formatDate(this.vencimiento);
  }

  /**
   * Encuentra el sábado más cercano a una fecha ancla dentro del margen permitido.
   * Se usa para alinear cobros con la quincena del propietario.
   */
  static sabadoCercano(ancla: Date, margen = MARGEN_QUINCENA_DIAS): Date {
    let mejor: Date | null = null;
    let menorDistancia = Infinity;

    for (let offset = -margen; offset <= margen; offset++) {
      const candidato = new Date(ancla);
      candidato.setDate(candidato.getDate() + offset);
      if (candidato.getDay() === 6) {
        const distancia = Math.abs(offset);
        if (distancia < menorDistancia) {
          menorDistancia = distancia;
          mejor = candidato;
        }
      }
    }

    if (mejor) return normalizeDate(mejor);

    const fallback = new Date(ancla);
    while (fallback.getDay() !== 6) {
      fallback.setDate(fallback.getDate() + 1);
    }
    return normalizeDate(fallback);
  }

  /**
   * Período del cobro mensual (siempre del día 1 al 1 del mes siguiente).
   * Un solo registro por mes; los abonos parciales se acumulan en montoPagado.
   */
  static calcularCuotaMensual(desde: Date): Periodo {
    return Periodo.calcularMensual(normalizeDate(desde));
  }

  /**
   * Fechas sugeridas de cobro parcial dentro del mes.
   * SEMANAL: cada sábado | QUINCENAL: cerca del 15 y fin de mes | MENSUAL: fin de mes.
   */
  static fechasCobroParciales(
    modalidad: ModalidadRecaudo,
    year: number,
    month: number,
  ): string[] {
    switch (modalidad) {
      case 'SEMANAL': {
        const fechas: string[] = [];
        const ultimoDia = toLocalDate(year, month + 1, 0).getDate();
        for (let d = 1; d <= ultimoDia; d++) {
          const fecha = toLocalDate(year, month, d);
          if (fecha.getDay() === 6) fechas.push(formatDate(fecha));
        }

        // Regla de negocio: Exactamente 4 pagos semanales por mes.
        if (fechas.length === 5) {
          const primerSabado = parseLocalDate(fechas[0]).getDate();
          if (primerSabado <= 2) {
            // Sábado cae 1 o 2: descartamos el primero (pertenece a la semana del mes anterior)
            fechas.shift();
          } else {
            // Sábado cae 3, 4 o 5: descartamos el último (su semana laboral corresponde al mes siguiente)
            fechas.pop();
          }
        }

        return fechas;
      }
      case 'QUINCENAL': {
        const ancla1 = toLocalDate(year, month, 15);
        const ultimoDia = toLocalDate(year, month + 1, 0);
        const d2 = new Date(ultimoDia);
        while (d2.getDay() !== 6) {
          d2.setDate(d2.getDate() - 1);
        }
        return [formatDate(Periodo.sabadoCercano(ancla1)), formatDate(d2)];
      }
      case 'MENSUAL': {
        const ultimoDia = toLocalDate(year, month + 1, 0);
        const d = new Date(ultimoDia);
        while (d.getDay() !== 6) {
          d.setDate(d.getDate() - 1);
        }
        return [formatDate(d)];
      }
    }
  }

  /**
   * Calcula el siguiente período de cobro parcial (solo referencia de calendario).
   * El cobro en BD siempre es mensual.
   */
  static calcularSiguiente(modalidad: ModalidadRecaudo, desde: Date): Periodo {
    const base = normalizeDate(desde);

    switch (modalidad) {
      case 'SEMANAL':
        return Periodo.calcularSemanal(base);
      case 'QUINCENAL':
        return Periodo.calcularQuincenal(base);
      case 'MENSUAL':
        return Periodo.calcularMensual(base);
    }
  }

  private static calcularSemanal(desde: Date): Periodo {
    const inicio = new Date(desde);
    while (inicio.getDay() !== 1) {
      inicio.setDate(inicio.getDate() + 1);
    }

    const fin = new Date(inicio);
    fin.setDate(fin.getDate() + 7);

    const vencimiento = new Date(inicio);
    vencimiento.setDate(vencimiento.getDate() + 5);

    return new Periodo(
      normalizeDate(inicio),
      normalizeDate(fin),
      normalizeDate(vencimiento),
    );
  }

  private static calcularQuincenal(desde: Date): Periodo {
    const day = desde.getDate();

    if (day <= 15) {
      const inicio = toLocalDate(desde.getFullYear(), desde.getMonth(), 1);
      const fin = toLocalDate(desde.getFullYear(), desde.getMonth(), 16);
      const ancla = toLocalDate(desde.getFullYear(), desde.getMonth(), 15);
      const vencimiento = Periodo.sabadoCercano(ancla);
      return new Periodo(inicio, fin, vencimiento);
    }

    const inicio = toLocalDate(desde.getFullYear(), desde.getMonth(), 16);
    const fin = toLocalDate(desde.getFullYear(), desde.getMonth() + 1, 1);
    const ultimoDia = toLocalDate(desde.getFullYear(), desde.getMonth() + 1, 0);
    const vencimiento = Periodo.sabadoCercano(ultimoDia);
    return new Periodo(inicio, fin, vencimiento);
  }

  private static calcularMensual(desde: Date): Periodo {
    const inicio = toLocalDate(desde.getFullYear(), desde.getMonth(), 1);
    const fin = toLocalDate(desde.getFullYear(), desde.getMonth() + 1, 1);
    const ultimoDia = toLocalDate(desde.getFullYear(), desde.getMonth() + 1, 0);
    const vencimiento = Periodo.sabadoCercano(ultimoDia);
    return new Periodo(inicio, fin, vencimiento);
  }

  /**
   * Fecha límite: solo el mes actual y el próximo mes son visibles/generables.
   */
  static limiteGeneracion(
    _modalidad?: ModalidadRecaudo,
    hoy = new Date(),
  ): Date {
    const ref = normalizeDate(hoy);
    return toLocalDate(ref.getFullYear(), ref.getMonth() + 1, 1);
  }

  /**
   * Determina si un cobro mensual debe mostrarse (mes actual o próximo).
   */
  static esVisible(
    periodoInicio: string,
    _modalidad?: ModalidadRecaudo,
    hoy = new Date(),
  ): boolean {
    const inicio = parseLocalDate(periodoInicio);
    const ref = normalizeDate(hoy);

    if (inicio <= ref) return true;

    const limite = Periodo.limiteGeneracion(undefined, ref);
    return inicio <= limite;
  }

  /**
   * Indica si un período ya puede generarse (su inicio llegó o es hoy).
   */
  static puedeGenerarse(periodo: Periodo, hoy = new Date()): boolean {
    const ref = normalizeDate(hoy);
    return periodo.inicio <= ref;
  }

  static formatConceptoCuotaMensual(periodo: Periodo): string {
    return `Cuota de Vigilancia`;
  }

  /** @deprecated Usar formatConceptoCuotaMensual para registros de cobro. */
  static formatConcepto(
    _modalidad: ModalidadRecaudo,
    periodo: Periodo,
  ): string {
    return Periodo.formatConceptoCuotaMensual(periodo);
  }

  /**
   * Calcula el monto prorrateado para el primer mes de registro, basado en las fechas de cobro restantes.
   */
  static calcularCuotaProrrateada(
    fechaRegistro: Date,
    modalidad: ModalidadRecaudo,
    tarifaMensualCentavos: number,
  ): number {
    const year = fechaRegistro.getFullYear();
    const month = fechaRegistro.getMonth();
    const fechasMes = Periodo.fechasCobroParciales(modalidad, year, month);

    // Contar cuántas fechas son mayores o iguales a la fecha de registro
    const registroStr = formatDate(fechaRegistro);
    const fechasRestantes = fechasMes.filter((f) => f >= registroStr).length;

    // totalPagos será 4, 2 o 1
    const totalPagos = pagosPorMes(modalidad);

    return Math.round((tarifaMensualCentavos / totalPagos) * fechasRestantes);
  }

  /**
   * Obtiene la próxima fecha de cobro y el monto parcial a cobrar en esa fecha.
   */
  static obtenerProximoPago(
    fechaBase: Date,
    modalidad: ModalidadRecaudo,
    tarifaMensualCentavos: number,
  ): { fecha: string; monto: number } | null {
    const year = fechaBase.getFullYear();
    const month = fechaBase.getMonth();

    // Buscar en el mes actual
    let fechas = Periodo.fechasCobroParciales(modalidad, year, month);
    const baseStr = formatDate(fechaBase);
    let proximas = fechas.filter((f) => f >= baseStr);

    // Si ya pasaron todas las de este mes, buscar en el siguiente
    if (proximas.length === 0) {
      const mesSiguiente = month === 11 ? 0 : month + 1;
      const anoSiguiente = month === 11 ? year + 1 : year;
      fechas = Periodo.fechasCobroParciales(
        modalidad,
        anoSiguiente,
        mesSiguiente,
      );
      proximas = fechas;
    }

    if (proximas.length === 0) return null; // No debería pasar

    const totalPagos = pagosPorMes(modalidad);
    const montoParcial = Math.round(tarifaMensualCentavos / totalPagos);

    return {
      fecha: proximas[0],
      monto: montoParcial,
    };
  }
}
