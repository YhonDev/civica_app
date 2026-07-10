import { Actividad } from './actividad.entity';

export abstract class ActividadRepository {
  abstract save(actividad: Actividad): Promise<Actividad>;
  abstract findByTenant(tenantId: string, limit: number): Promise<Actividad[]>;
}
