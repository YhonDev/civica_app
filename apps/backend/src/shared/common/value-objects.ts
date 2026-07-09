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
