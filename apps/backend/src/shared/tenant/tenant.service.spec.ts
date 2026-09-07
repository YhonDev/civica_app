import { TenantService } from './tenant.service';

describe('TenantService', () => {
  let service: TenantService;

  beforeEach(() => {
    service = new TenantService();
  });

  function crearRequest(user: unknown) {
    return { user } as never;
  }

  it('extrae el tenantId del usuario autenticado', () => {
    const tenantId = service.getTenantIdFromRequest(
      crearRequest({ tenantId: 'tenant-abc' }),
    );
    expect(tenantId).toBe('tenant-abc');
  });

  it('retorna null si la request no trae usuario', () => {
    expect(service.getTenantIdFromRequest(crearRequest(undefined))).toBeNull();
  });

  it('retorna null si el usuario no tiene tenantId', () => {
    expect(service.getTenantIdFromRequest(crearRequest({ rol: 'ADMIN' }))).toBeNull();
  });

  it('extrae el tenantId desde el ExecutionContext HTTP', () => {
    const context = {
      switchToHttp: () => ({
        getRequest: () => crearRequest({ tenantId: 'tenant-xyz' }),
      }),
    } as never;

    expect(service.getTenantIdFromExecutionContext(context)).toBe('tenant-xyz');
  });

  it('retorna null desde un ExecutionContext sin usuario', () => {
    const context = {
      switchToHttp: () => ({
        getRequest: () => ({}),
      }),
    } as never;

    expect(service.getTenantIdFromExecutionContext(context)).toBeNull();
  });
});
