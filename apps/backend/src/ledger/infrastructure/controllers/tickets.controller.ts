import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { TicketRepository } from '../persistence/ticket.repository';
import { mapTicketToResponse } from '../../application/mappers/ticket.mapper';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';

@ApiTags('Tickets')
@ApiBearerAuth('jwt-auth')
@Controller('tickets')
@UseGuards(JwtAuthGuard)
export class TicketsController {
  constructor(private readonly ticketRepo: TicketRepository) {}

  /**
   * GET /tickets/:id
   * Returns a single ticket by ID.
   * Response fields vary by role (RESIDENTE < COBRADOR < ADMIN).
   */
  @Get(':id')
  async getById(@Param('id') id: string, @CurrentUser() user: Usuario) {
    const ticket = await this.ticketRepo.findById(id);
    if (!ticket) {
      throw new NotFoundException(`Ticket ${id} no encontrado`);
    }
    return mapTicketToResponse(ticket, this.resolveProjection(user.rol));
  }

  /**
   * GET /tickets?residenteId=X
   * Returns tickets for a specific residente.
   * Used by all roles to view payment history.
   */
  @Get()
  async list(
    @Query('residenteId') residenteId: string,
    @Query('pagoId') pagoId: string,
    @Query('limit') limit: string,
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const projection = this.resolveProjection(user.rol);

    // By pagoId — find the ticket for a specific payment
    if (pagoId) {
      const ticket = await this.ticketRepo.findByPago(pagoId);
      if (!ticket) {
        throw new NotFoundException(`Ticket para pago ${pagoId} no encontrado`);
      }
      return mapTicketToResponse(ticket, projection);
    }

    // By residenteId — list tickets for a residente
    if (residenteId) {
      const tickets = await this.ticketRepo.findByResidente(residenteId, {
        limit: limit ? parseInt(limit, 10) : undefined,
      });
      return tickets.map((t) => mapTicketToResponse(t, projection));
    }

    // Default: all tickets for the tenant (admin only)
    if (user.rol !== RolUsuario.ADMIN) {
      return [];
    }

    const tickets = await this.ticketRepo.findByTenantPaginated(tenantId, {
      limit: limit ? parseInt(limit, 10) : 50,
    });
    return tickets.map((t) => mapTicketToResponse(t, projection));
  }

  /**
   * GET /tickets/numero/:numero
   * Find a ticket by its sequential number (TKT-YYYY-NNNNNN).
   * Primarily for ADMIN traceability lookups.
   */
  @Get('numero/:numero')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async getByNumero(
    @Param('numero') numero: string,
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const ticket = await this.ticketRepo.findByNumero(tenantId, numero);
    if (!ticket) {
      throw new NotFoundException(`Ticket ${numero} no encontrado`);
    }
    return mapTicketToResponse(ticket, 'ADMIN');
  }

  private resolveProjection(
    rol: RolUsuario,
  ): 'RESIDENTE' | 'COBRADOR' | 'ADMIN' {
    switch (rol) {
      case RolUsuario.ADMIN:
        return 'ADMIN';
      case RolUsuario.COBRADOR:
        return 'COBRADOR';
      default:
        return 'RESIDENTE';
    }
  }
}
