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
import { PlanDeCobroRepository } from '../../../ledger/infrastructure/persistence/plan-de-cobro.repository';
import { GenerarCobrosUseCase } from '../../../ledger/application/use-cases/generar-cobros.use-case';
import { PlanDeCobro } from '../../../ledger/domain/plan-de-cobro.entity';

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
    private readonly planDeCobroRepository: PlanDeCobroRepository,
    private readonly generarCobrosUC: GenerarCobrosUseCase,
  ) {}

  async execute(
    params: RegistrarResidenteParams,
  ): Promise<ResultadoRegistroResidente> {
    const residente = Residente.crear(
      params.nombre,
      params.telefono,
      params.email,
      params.tenantId,
      params.modalidadPago,
    );

    const saved = await this.residenteRepository.save(residente);

    let username: string;
    let password: string;
    let casa: Casa | null = null;

    if (params.casaId) {
      casa = await this.casaRepository.findOne({
        where: { id: params.casaId },
        relations: { manzana: { etapa: true } },
      });
    }

    // Si se proporcionó una casa, crear tenencia y plan de cobro
    if (params.casaId && casa) {
      const fechaInicio = params.fechaInicio ?? new Date();
      saved.agregarTenencia(params.casaId, fechaInicio);
      saved.asignarCasa(params.casaId);
      await this.residenteRepository.save(saved);

      if (casa.manzana?.etapa?.proyectoId) {
        const fechaActivacionStr = fechaInicio.toISOString().split('T')[0];
        const plan = PlanDeCobro.crear(
          params.casaId,
          saved.id,
          params.tenantId,
          casa.manzana.etapa.proyectoId,
          saved.modalidadPago,
          fechaActivacionStr,
        );
        const planSaved = await this.planDeCobroRepository.save(plan);

        // Generar cobros inmediatamente para el mes actual
        const mes = fechaInicio.getMonth() + 1;
        const anio = fechaInicio.getFullYear();
        await this.generarCobrosUC.generarCobrosParaPlan(
          planSaved,
          mes,
          anio,
          fechaInicio,
        );
      }
    }

    if (params.casaId && casa) {
      const etapaNombre = casa.manzana?.etapa?.nombre;
      const manzanaNombre = casa.manzana?.nombre ?? 'mz';
      const casaDireccion = casa.direccionInterna ?? params.casaId;
      username = this.generarCredenciales.generarUsernameResidente(
        manzanaNombre,
        casaDireccion,
        etapaNombre,
      );
      password = this.generarCredenciales.generarPasswordResidente(
        manzanaNombre,
        casaDireccion,
      );
    } else {
      username = `residente_${saved.id.substring(0, 8)}`;
      password = this.generarCredenciales.generarPasswordAleatoria();
    }

    // Asegurar unicidad de username si ya existiese
    const baseUsername = username;
    let counter = 1;
    while (
      await this.usuarioRepository.findOne({ where: { email: username } })
    ) {
      counter++;
      username = `${baseUsername}_${counter}`;
    }

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
