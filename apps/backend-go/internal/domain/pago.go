package domain

import "time"

// EstadoValidacionPago represents the validation state of a payment
type EstadoValidacionPago string

const (
	EstadoPENDIENTE_REVISION EstadoValidacionPago = "PENDIENTE_REVISION"
	EstadoVALIDADO           EstadoValidacionPago = "VALIDADO"
	EstadoRECHAZADO          EstadoValidacionPago = "RECHAZADO"
)

// Pago represents a payment record
type Pago struct {
	ID              string              `db:"id" json:"id"`
	ClientPaymentID string              `db:"client_payment_id" json:"clientPaymentId"`
	TenantID        string              `db:"tenant_id" json:"tenantId"`
	CobroID         *string             `db:"cobro_id" json:"cobroId"`
	Monto           int                 `db:"monto" json:"monto"`
	FechaPago       string              `db:"fecha_pago" json:"fechaPago"`
	CobradorID      string              `db:"cobrador_id" json:"cobradorId"`
	ResidenteID     string              `db:"residente_id" json:"residenteId"`
	FechaSync       *time.Time          `db:"fecha_sync" json:"fechaSync"`
	SyncStatus      string              `db:"sync_status" json:"syncStatus"`
	Estado          EstadoValidacionPago `db:"estado" json:"estado"`
	CreatedAt       time.Time           `db:"created_at" json:"createdAt"`
	UpdatedAt       time.Time           `db:"updated_at" json:"updatedAt"`
}

// CrearPago creates a new Pago instance
func CrearPago(
	clientPaymentId, tenantId string,
	monto int,
	fechaPago, cobradorId, residenteId string,
	cobroId *string,
) *Pago {
	return &Pago{
		ClientPaymentID: clientPaymentId,
		TenantID:        tenantId,
		Monto:           monto,
		FechaPago:       fechaPago,
		CobradorID:      cobradorId,
		ResidenteID:     residenteId,
		CobroID:         cobroId,
		SyncStatus:      "SYNC_OK",
		Estado:          EstadoPENDIENTE_REVISION,
	}
}
