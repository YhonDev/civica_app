import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';

/**
 * Genera credenciales de acceso (username y password) según el rol
 * siguiendo los patrones definidos en la Filosofía del Sistema.
 *
 * Patrones:
 * - RESIDENTE: username = "{manzana}_{casa}_residente", password = "Casa{casa}Manzana{manzana}"
 * - COBRADOR:  username = "{nombre}{primerApellido}cobrador", password = "{nombre}{primerApellido}{añoActual}"
 * - ADMIN:     se crea manualmente, sin patrón automático
 */
@Injectable()
export class GenerarCredencialesService {
  generarUsernameResidente(
    manzana: string,
    casa: string,
    etapa?: string,
  ): string {
    const mz = manzana
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
    const cs = casa
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
    if (etapa && etapa.trim() !== '') {
      const et = etapa
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9_]/g, '');
      return `${et}_${mz}_${cs}_residente`;
    }
    return `${mz}_${cs}_residente`;
  }

  /**
   * Generar password temporal para un residente basado en su ubicación.
   * Ej: "Casa1ManzanaA"
   */
  generarPasswordResidente(manzana: string, casa: string): string {
    const mz = manzana
      .toLowerCase()
      .replace(/manzana/g, '')
      .trim()
      .toUpperCase()
      .replace(/\s+/g, '');
    const cs = casa
      .toLowerCase()
      .replace(/casa/g, '')
      .trim()
      .toUpperCase()
      .replace(/\s+/g, '');
    return `Casa${cs}Manzana${mz}`;
  }

  /**
   * Genera username para un cobrador basado en su nombre y primer apellido.
   * Ej: "juanperezcobrador"
   */
  generarUsernameCobrador(nombreCompleto: string): string {
    const partes = nombreCompleto.trim().split(/\s+/);
    const nombre = partes[0]?.toLowerCase() ?? '';
    const primerApellido = partes[1]?.toLowerCase() ?? '';
    const base = `${nombre}${primerApellido}`.replace(/[^a-z0-9]/g, '');
    return `${base}cobrador`;
  }

  /**
   * Genera password para un cobrador: nombre + primer apellido + año actual.
   * Ej: "juanperez2026"
   */
  generarPasswordCobrador(nombreCompleto: string): string {
    const partes = nombreCompleto.trim().split(/\s+/);
    const nombre = partes[0]?.toLowerCase() ?? '';
    const primerApellido = partes[1]?.toLowerCase() ?? '';
    const base = `${nombre}${primerApellido}`.replace(/[^a-z0-9]/g, '');
    const anio = new Date().getFullYear().toString();
    return `${base}${anio}`;
  }

  /**
   * Genera una contraseña aleatoria segura de 10 caracteres.
   * Usa caracteres alfanuméricos (mayúsculas, minúsculas, dígitos).
   */
  generarPasswordAleatoria(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    const bytes = crypto.randomBytes(10);
    let password = '';
    for (let i = 0; i < 10; i++) {
      password += chars[bytes[i] % chars.length];
    }
    return password;
  }
}
