package domain

import (
	"errors"
	"time"
)

// Cobro represents a bill/charge for a resident
type Cobro struct {
	ID                string     `db:"id" json:"id"`
	ResidenteID       string     `db:"residente_id" json:"residenteId"`
	TenantID          string     `db:"tenant_id" json:"tenantId"`
	PeriodoID         *string    `db:"periodo_id" json:"periodoId"`
	CasaID            *string    `db:"casa_id" json:"casaId"`
	TarifaID          *string    `db:"tarifa_id" json:"tarifaId"`
	Concepto          string     `db:"concepto" json:"concepto"`
	Monto             int        `db:"monto" json:"monto"`
	MontoPagado       int        `db:"monto_pagado" json:"montoPagado"`
	PeriodoInicio     string     `db:"periodo_inicio" json:"periodoInicio"`
	PeriodoFin        string     `db:"periodo_fin" json:"periodoFin"`
	FechaVencimiento  string     `db:"fecha_vencimiento" json:"fechaVencimiento"`
	Estado            EstadoCobro `db:"estado" json:"estado"`
	NotificacionEnviada bool    `db:"notificacion_enviada" json:"notificacionEnviada"`
	CreatedAt         time.Time  `db:"created_at" json:"createdAt"`
	UpdatedAt         time.Time  `db:"updated_at" json:"updatedAt"`
}

// Saldo returns the pending amount
func (c *Cobro) Saldo() int {
	return c.Monto - c.MontoPagado
}

// AplicarPago applies a payment to this cobro using FIFO
// Returns the excess amount if payment exceeds saldo
func (c *Cobro) AplicarPago(montoPago int) (excedente int, err error) {
	if c.Estado == EstadoPAGADA {
		return 0, errors.New("no se puede pagar un cobro ya PAGADO")
	}
	if c.Estado == EstadoANULADO {
		return 0, errors.New("no se puede pagar un cobro en estado ANULADO")
	}

	saldo := c.Saldo()
	if montoPago >= saldo {
		excedente = montoPago - saldo
		c.MontoPagado += saldo
		c.Estado = EstadoPAGADA
		return excedente, nil
	}

	c.MontoPagado += montoPago
	c.Estado = EstadoPARCIAL
	return 0, nil
}

// MarcarVencida marks the cobro as overdue
func (c *Cobro) MarcarVencida() {
	if c.Estado == EstadoPENDIENTE || c.Estado == EstadoPARCIAL {
		c.Estado = EstadoVENCIDA
	}
}

// EstaPagada returns true if the cobro is fully paid
func (c *Cobro) EstaPagada() bool {
	return c.Estado == EstadoPAGADA
}

// EstaVencida returns true if the cobro is overdue
func (c *Cobro) EstaVencida() bool {
	return c.Estado == EstadoVENCIDA
}

// EstaPendiente returns true if the cobro is pending
func (c *Cobro) EstaPendiente() bool {
	return c.Estado == EstadoPENDIENTE
}

// Crear creates a new Cobro instance
func CrearCobro(
	residenteId, tenantId, concepto string,
	monto int,
	periodoInicio, periodoFin, fechaVencimiento string,
	tarifaId, periodoId, casaId *string,
) *Cobro {
	return &Cobro{
		ResidenteID:      residenteId,
		TenantID:         tenantId,
		Concepto:         concepto,
		Monto:            monto,
		MontoPagado:      0,
		PeriodoInicio:    periodoInicio,
		PeriodoFin:       periodoFin,
		FechaVencimiento: fechaVencimiento,
		Estado:           EstadoPENDIENTE,
		TarifaID:         tarifaId,
		PeriodoID:        periodoId,
		CasaID:           casaId,
	}
}
