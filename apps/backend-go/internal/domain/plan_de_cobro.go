package domain

import "time"

// PlanDeCobro represents a billing plan for a resident
type PlanDeCobro struct {
	ID             string           `db:"id" json:"id"`
	CasaID         *string          `db:"casa_id" json:"casaId"`
	ResidenteID    string           `db:"residente_id" json:"residenteId"`
	TenantID       string           `db:"tenant_id" json:"tenantId"`
	ProyectoID     string           `db:"proyecto_id" json:"proyectoId"`
	Modalidad      ModalidadRecaudo `db:"modalidad" json:"modalidad"`
	ValorMensual   *int             `db:"valor_mensual" json:"valorMensual"`
	FechaActivacion string          `db:"fecha_activacion" json:"fechaActivacion"`
	Activa         bool             `db:"activa" json:"activa"`
	CreatedAt      time.Time        `db:"created_at" json:"createdAt"`
	UpdatedAt      time.Time        `db:"updated_at" json:"updatedAt"`
}

// CrearPlanDeCobro creates a new PlanDeCobro instance
func CrearPlanDeCobro(
	casaId *string,
	residenteId, tenantId, proyectoId string,
	modalidad ModalidadRecaudo,
	fechaActivacion string,
	valorMensual *int,
) *PlanDeCobro {
	return &PlanDeCobro{
		CasaID:          casaId,
		ResidenteID:     residenteId,
		TenantID:        tenantId,
		ProyectoID:      proyectoId,
		Modalidad:       modalidad,
		FechaActivacion: fechaActivacion,
		ValorMensual:    valorMensual,
		Activa:          true,
	}
}

// Desactivar deactivates the plan
func (p *PlanDeCobro) Desactivar() {
	p.Activa = false
}
