package domain

import "time"

// Tarifa represents a rate/fee for a project
type Tarifa struct {
	ID           string           `db:"id" json:"id"`
	TenantID     string           `db:"tenant_id" json:"tenantId"`
	ProyectoID   string           `db:"proyecto_id" json:"proyectoId"`
	Modalidad    ModalidadRecaudo `db:"modalidad" json:"modalidad"`
	Monto        int              `db:"monto" json:"monto"`
	FechaVigencia string          `db:"fecha_vigencia" json:"fechaVigencia"`
	Activa       bool             `db:"activa" json:"activa"`
	CreatedAt    time.Time        `db:"created_at" json:"createdAt"`
	UpdatedAt    time.Time        `db:"updated_at" json:"updatedAt"`
}

// CrearTarifa creates a new Tarifa instance
func CrearTarifa(
	proyectoId, tenantId string,
	modalidad ModalidadRecaudo,
	monto int,
	fechaVigencia string,
) *Tarifa {
	return &Tarifa{
		ProyectoID:    proyectoId,
		TenantID:      tenantId,
		Modalidad:     modalidad,
		Monto:         monto,
		FechaVigencia: fechaVigencia,
		Activa:        true,
	}
}

// Desactivar deactivates the tariff
func (t *Tarifa) Desactivar() {
	t.Activa = false
}
