import { Test, TestingModule } from '@nestjs/testing';
import * as crypto from 'crypto';

import { GenerarCredencialesService } from './generar-credenciales.service';

jest.mock('crypto');

describe('GenerarCredencialesService', () => {
  let service: GenerarCredencialesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GenerarCredencialesService],
    }).compile();

    service = module.get<GenerarCredencialesService>(
      GenerarCredencialesService,
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── generarUsernameResidente ─────────────────────────

  describe('generarUsernameResidente', () => {
    it('should generate username from manzana and casa', () => {
      const result = service.generarUsernameResidente('Manzana A', 'Lote 23');
      expect(result).toBe('manzana_a_lote_23_residente');
    });

    it('should handle single-word manzana', () => {
      const result = service.generarUsernameResidente('Alfa', 'Casa 5');
      expect(result).toBe('alfa_casa_5_residente');
    });

    it('should strip special characters', () => {
      const result = service.generarUsernameResidente('Manzana B/C', 'Casa#1!');
      expect(result).toBe('manzana_bc_casa1_residente');
    });

    it('should handle empty strings gracefully', () => {
      const result = service.generarUsernameResidente('', '');
      expect(result).toBe('__residente');
    });
  });

  // ─── generarUsernameCobrador ──────────────────────────

  describe('generarUsernameCobrador', () => {
    it('should generate username from first name and surname', () => {
      const result = service.generarUsernameCobrador('Juan Perez');
      expect(result).toBe('juanperezcobrador');
    });

    it('should handle compound first names', () => {
      const result = service.generarUsernameCobrador('Carlos Andres Lopez');
      expect(result).toBe('carlosandrescobrador');
    });

    it('should handle single name (no surname)', () => {
      const result = service.generarUsernameCobrador('Admin');
      expect(result).toBe('admincobrador');
    });

    it('should strip accents and special chars', () => {
      // Accented chars (é, í) are stripped by [^a-z0-9] regex, not converted
      const result = service.generarUsernameCobrador('José Martínez');
      expect(result).toBe('josmartnezcobrador');
    });

    it('should trim extra whitespace', () => {
      const result = service.generarUsernameCobrador('  Maria  Gomez  ');
      expect(result).toBe('mariagomezcobrador');
    });
  });

  // ─── generarPasswordCobrador ──────────────────────────

  describe('generarPasswordCobrador', () => {
    it('should generate password from name + surname + current year', () => {
      const currentYear = new Date().getFullYear().toString();
      const result = service.generarPasswordCobrador('Luis Torres');
      expect(result).toBe(`luistorres${currentYear}`);
    });

    it('should handle single name', () => {
      const currentYear = new Date().getFullYear().toString();
      const result = service.generarPasswordCobrador('Admin');
      expect(result).toBe(`admin${currentYear}`);
    });

    it('should strip special characters', () => {
      const currentYear = new Date().getFullYear().toString();
      const result = service.generarPasswordCobrador("Pepe's García");
      // Accented í is stripped by [^a-z0-9], not converted to i
      expect(result).toBe(`pepesgarca${currentYear}`);
    });

    it('should always end with 4-digit year', () => {
      const result = service.generarPasswordCobrador('Test User');
      expect(result).toMatch(/testuser\d{4}$/);
    });
  });

  // ─── generarPasswordAleatoria ─────────────────────────

  describe('generarPasswordAleatoria', () => {
    it('should generate a 10-character password', () => {
      // Mock crypto.randomBytes to return predictable values
      const mockBytes = Buffer.alloc(10, 0); // all zeros → index 0 → 'A'
      (crypto.randomBytes as jest.Mock).mockReturnValue(mockBytes);

      const result = service.generarPasswordAleatoria();

      expect(result).toHaveLength(10);
    });

    it('should only contain characters from the allowed set', () => {
      const mockBytes = Buffer.from([0, 5, 10, 15, 20, 25, 30, 35, 40, 45]);
      (crypto.randomBytes as jest.Mock).mockReturnValue(mockBytes);

      const result = service.generarPasswordAleatoria();

      const allowed = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      for (const char of result) {
        expect(allowed).toContain(char);
      }
    });

    it('should not contain easily confused characters (0, O, I, 1)', () => {
      const mockBytes = Buffer.from([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      (crypto.randomBytes as jest.Mock).mockReturnValue(mockBytes);

      const result = service.generarPasswordAleatoria();

      expect(result).not.toContain('0');
      expect(result).not.toContain('O');
      expect(result).not.toContain('I');
      expect(result).not.toContain('1');
    });

    it('should generate different passwords on subsequent calls', () => {
      // First call with bytes [0..9]
      (crypto.randomBytes as jest.Mock)
        .mockReturnValueOnce(Buffer.from([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]))
        // Second call with bytes [9..0]
        .mockReturnValueOnce(Buffer.from([9, 8, 7, 6, 5, 4, 3, 2, 1, 0]));

      const first = service.generarPasswordAleatoria();
      const second = service.generarPasswordAleatoria();

      expect(first).not.toBe(second);
    });
  });
});
