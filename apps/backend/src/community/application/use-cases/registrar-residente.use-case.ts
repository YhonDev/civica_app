import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Residente } from '../../domain/residente.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { type ModalidadRecaudo } from '../../../shared/common/value-objects';
import { GenerarCredencialesService } from '../../../iam/application/services/generar-credenciales.service';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import { Casa } from '../../domain/casa.entity';

interface RegistrarResidenteParams {
  nombre: string;
  telefono: string;
  email: string | null;
  tenantId: string;
  casaId?: string;
  fechaInicio?: Date;
  modalidadPago?: ModalidadRecaudo;
}

interface ResultadoRegistroResidente {
  residente: Residente;
  credenciales: {
    username: string;
    password: string;
  };
}

@Injectable()
export class RegistrarResidenteUseCase {
  constructor(
    private readonly residenteRepository: ResidenteRepository,
    private readonly generarCredenciales: GenerarCredencialesService,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(Casa)
    private readonly casaRepository: Repository<Casa>,
  ) {}

  async execute(params: RegistrarResidenteParams): Promise<ResultadoRegistroResidente> {
    const residente = Residente.crear(
      params.nombre,
      params.telefono,
      params.email,
      params.tenantId,
      params.modalidadPago,
    );

    const saved = await this.residenteRepository.save(residente);

    // Si se proporcionó una casa, crear tenencia
    if (params.casaId) {
      const fechaInicio = params.fechaInicio ?? new Date();
      saved.agregarTenencia(params.casaId, fechaInicio);
      await this.residenteRepository.save(saved);
    }

    // Generar username basado en la casa (manzana + casa)
    let username: string;
    let password: string;

    if (params.casaId) {
      const casa = await this.casaRepository.findOne({
        where: { id: params.casaId },
        relations: { manzana: true },
      });
      const manzanaNombre = casa?.manzana?.nombre ?? 'mz';
      const casaDireccion = casa?.direccionInterna ?? params.casaId;
      username = this.generarCredenciales.generarUsernameResidente(
        manzanaNombre,
        casaDireccion,
      );
    } else {
      username = `residente_${saved.id.substring(0, 8)}`;
    }

    password = this.generarCredenciales.generarPasswordAleatoria();
    const passwordHash = await bcrypt.hash(password, 10);

    // Crear el usuario automáticamente
    const usuario = Usuario.crear(
      username,
      passwordHash,
      saved.nombre,
      RolUsuario.RESIDENTE,
      params.tenantId,
      saved.id,
    );

    await this.usuarioRepository.save(usuario);

    return {
      residente: saved,
      credenciales: { username, password },
    };
  }
}
