package config

import "os"

type Config struct {
	Port      string
	DBURL     string
	JWTSecret string
	CORSOrigin string
}

func Load() *Config {
	return &Config{
		Port:       getEnv("PORT", "3000"),
		DBURL:      getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/civica?sslmode=disable"),
		JWTSecret:  getEnv("JWT_SECRET", "change-this-secret"),
		CORSOrigin: getEnv("CORS_ORIGIN", "http://localhost:3000"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
