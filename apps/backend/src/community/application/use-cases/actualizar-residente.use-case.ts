import {
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Residente } from '../../domain/residente.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { Casa } from '../../domain/casa.entity';
import { type ModalidadRecaudo } from '../../../shared/common/value-objects';
import { ReconciliarModalidadUseCase } from '../../../ledger/application/use-cases/reconciliar-modalidad.use-case';

interface ActualizarResidenteParams {
  id: string;
  tenantId: string;
  nombre?: string;
  telefono?: string;
  email?: string | null;
  casaId?: string;
  modalidadPago?: ModalidadRecaudo;
}

@Injectable()
export class ActualizarResidenteUseCase {
  constructor(
    private readonly residenteRepository: ResidenteRepository,
    @Inject(forwardRef(() => ReconciliarModalidadUseCase))
    private readonly reconciliarModalidadUseCase: ReconciliarModalidadUseCase,
    @InjectRepository(Casa)
    private readonly casaRepository: Repository<Casa>,
  ) {}

  async execute(params: ActualizarResidenteParams): Promise<void> {
    const residente = await this.residenteRepository.findById(
      params.id,
      params.tenantId,
    );

    if (!residente) {
      throw new NotFoundException('Residente no encontrado');
    }

    const modalidadCambio =
      params.modalidadPago !== undefined &&
      params.modalidadPago !== residente.modalidadPago;

    if (params.nombre !== undefined) residente.nombre = params.nombre;
    if (params.telefono !== undefined) residente.telefono = params.telefono;
    if (params.email !== undefined) residente.email = params.email;
    if (params.modalidadPago !== undefined) {
      residente.modalidadPago = params.modalidadPago;
    }
    if (params.casaId !== undefined) {
      const casa = await this.casaRepository.findOne({
        where: { id: params.casaId },
        relations: { manzana: { etapa: { proyecto: true } } },
      });
      if (
        !casa ||
        casa.manzana?.etapa?.proyecto?.tenantId !== params.tenantId
      ) {
        throw new NotFoundException('Casa no encontrada en el tenant actual');
      }
      residente.asignarCasa(params.casaId);
    }

    await this.residenteRepository.save(residente);

    // Reconciliar cobros y pagos del mes activo si cambió la modalidad
    if (modalidadCambio && params.modalidadPago) {
      await this.reconciliarModalidadUseCase.execute(
        residente.id,
        params.modalidadPago,
        params.tenantId,
      );
    }
  }
}
