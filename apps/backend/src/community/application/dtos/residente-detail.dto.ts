export interface ResidenteDetailDto {
  id: string;
  tipo: 'PROPIETARIO' | 'INQUILINO';
  nombre: string;
  telefono: string;
  email: string | null;
  documento: string | null;
  casaActualId: string | null;
  modalidadPago: string;
  tenantId: string;
  username: string | null;
  tenencias: {
    id: string;
    casaId: string;
    fechaInicio: Date;
    fechaFin: Date | null;
    casa?: {
      direccionInterna: string;
      manzana?: {
        nombre: string;
        etapa?: {
          nombre: string;
        };
      };
    };
  }[];
}
