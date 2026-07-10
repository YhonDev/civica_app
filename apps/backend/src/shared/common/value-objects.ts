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
      throw new Error(`Teléfono inválido: ${value}. Debe tener entre 7 y 15 dígitos.`);
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

export type Frecuencia = 'SEMANAL' | 'QUINCENAL' | 'MENSUAL';

export class Money {
  constructor(
    public readonly amount: number,    // en centavos (integer)
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
    if (this.currency !== other.currency) throw new Error('No se pueden sumar monedas distintas');
    return new Money(this.amount + other.amount, this.currency);
  }

  subtract(other: Money): Money {
    if (this.currency !== other.currency) throw new Error('No se pueden restar monedas distintas');
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

export type EstadoCuota = 'PENDIENTE' | 'PARCIAL' | 'PAGADA' | 'VENCIDA';

export type SyncStatus = 'PENDIENTE_SYNC' | 'SYNC_OK' | 'CONFLICTO';

export class Periodo {
  constructor(
    public readonly inicio: Date,
    public readonly fin: Date,
    public readonly vencimiento: Date,
  ) {}

  static calcularSiguiente(frecuencia: Frecuencia, desde: Date): Periodo {
    const inicio = new Date(desde);
    const fin = new Date(desde);
    const vencimiento = new Date(desde);

    switch (frecuencia) {
      case 'SEMANAL':
        fin.setDate(fin.getDate() + 7);
        vencimiento.setDate(vencimiento.getDate() + 7);
        break;
      case 'QUINCENAL':
        fin.setDate(fin.getDate() + 15);
        vencimiento.setDate(vencimiento.getDate() + 15);
        break;
      case 'MENSUAL':
        fin.setMonth(fin.getMonth() + 1);
        vencimiento.setMonth(vencimiento.getMonth() + 1);
        break;
    }

    return new Periodo(inicio, fin, vencimiento);
  }
}
