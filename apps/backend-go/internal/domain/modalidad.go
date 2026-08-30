package domain

// ModalidadRecaudo represents the payment frequency
type ModalidadRecaudo string

const (
	SEMANAL   ModalidadRecaudo = "SEMANAL"
	QUINCENAL ModalidadRecaudo = "QUINCENAL"
	MENSUAL   ModalidadRecaudo = "MENSUAL"
)

// PagosPorMes returns the number of payments per month for a modality
func PagosPorMes(m ModalidadRecaudo) int {
	switch m {
	case SEMANAL:
		return 4
	case QUINCENAL:
		return 2
	case MENSUAL:
		return 1
	default:
		return 1
	}
}

// MontoMensualDesde converts a payment amount to monthly equivalent
func MontoMensualDesde(m ModalidadRecaudo, montoCentavos int) int {
	return montoCentavos * PagosPorMes(m)
}

// TarifasDerivadas calculates the 3 tariffs from monthly amount
func TarifasDerivadas(montoMensualCentavos int) map[ModalidadRecaudo]int {
	return map[ModalidadRecaudo]int{
		MENSUAL:   montoMensualCentavos,
		QUINCENAL: montoMensualCentavos / 2,
		SEMANAL:   montoMensualCentavos / 4,
	}
}
