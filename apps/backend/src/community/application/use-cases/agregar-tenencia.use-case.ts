import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenencia } from '../../domain/tenencia.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { Casa } from '../../domain/casa.entity';
import { PlanDeCobroRepository } from '../../../ledger/infrastructure/persistence/plan-de-cobro.repository';
import { GenerarCobrosUseCase } from '../../../ledger/application/use-cases/generar-cobros.use-case';
import { PlanDeCobro } from '../../../ledger/domain/plan-de-cobro.entity';

@Injectable()
export class AgregarTenenciaUseCase {
  constructor(
    private readonly residenteRepository: ResidenteRepository,
    @InjectRepository(Casa)
    private readonly casaRepository: Repository<Casa>,
    private readonly planDeCobroRepository: PlanDeCobroRepository,
    private readonly generarCobrosUC: GenerarCobrosUseCase,
  ) {}

  async execute(params: {
    residenteId: string;
    casaId: string;
    fechaInicio: Date;
    tenantId: string;
  }): Promise<Tenencia> {
    const residente = await this.residenteRepository.findWithTenencia(
      params.residenteId,
      params.tenantId,
    );
    if (!residente) {
      throw new NotFoundException(
        `Residente con ID ${params.residenteId} no encontrado`,
      );
    }

    const tenencia = residente.agregarTenencia(
      params.casaId,
      params.fechaInicio,
    );
    await this.residenteRepository.save(residente);

    // Buscar casa con proyectoId
    const casa = await this.casaRepository.findOne({
      where: { id: params.casaId },
      relations: { manzana: { etapa: true } },
    });

    if (casa?.manzana?.etapa?.proyectoId) {
      const fechaActivacionStr = params.fechaInicio.toISOString().split('T')[0];
      const plan = PlanDeCobro.crear(
        params.casaId,
        residente.id,
        residente.tenantId,
        casa.manzana.etapa.proyectoId,
        residente.modalidadPago,
        fechaActivacionStr,
      );
      const planSaved = await this.planDeCobroRepository.save(plan);

      // Generar cobros inmediatamente para el mes actual de ingreso
      const mes = params.fechaInicio.getMonth() + 1;
      const anio = params.fechaInicio.getFullYear();
      await this.generarCobrosUC.generarCobrosParaPlan(
        planSaved,
        mes,
        anio,
        params.fechaInicio,
      );
    }

    return tenencia;
  }
}
