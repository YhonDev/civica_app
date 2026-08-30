package domain

import "errors"

// Money represents a monetary amount in COP cents
type Money struct {
	Amount   int    `json:"amount"`
	Currency string `json:"currency"`
}

// NewMoney creates a new Money instance
func NewMoney(amount int) Money {
	return Money{Amount: amount, Currency: "COP"}
}

// OfCOP creates Money from pesos (converts to cents)
func OfCOP(pesos int) Money {
	return NewMoney(pesos * 100)
}

// OfCOPCentavos creates Money from centavos directly
func OfCOPCentavos(centavos int) Money {
	return NewMoney(centavos)
}

func (m Money) Add(other Money) Money {
	return Money{Amount: m.Amount + other.Amount, Currency: "COP"}
}

func (m Money) Subtract(other Money) (Money, error) {
	result := m.Amount - other.Amount
	if result < 0 {
		return Money{}, errors.New("saldo no puede ser negativo")
	}
	return Money{Amount: result, Currency: "COP"}, nil
}

func (m Money) IsZero() bool {
	return m.Amount == 0
}

func (m Money) Pesos() int {
	return m.Amount / 100
}
