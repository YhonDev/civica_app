package domain

// EstadoCobro represents the state of a cobro (bill/charge)
type EstadoCobro string

const (
	EstadoPENDIENTE EstadoCobro = "PENDIENTE"
	EstadoPARCIAL   EstadoCobro = "PARCIAL"
	EstadoPAGADA    EstadoCobro = "PAGADA"
	EstadoVENCIDA   EstadoCobro = "VENCIDA"
	EstadoANULADO   EstadoCobro = "ANULADO"
)
