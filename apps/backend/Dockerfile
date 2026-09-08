# ── Stage 1: Build ──────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Instalar dependencias completas para compilar TypeScript
COPY package*.json ./
RUN npm ci

# Copiar código fuente y compilar NestJS
COPY tsconfig*.json nest-cli.json ./
COPY src/ ./src/
RUN npm run build

# ── Stage 2: Production Runtime ─────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Instalar únicamente dependencias de producción
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copiar bundle compilado del builder
COPY --from=builder /app/dist ./dist

# Copiar esquemas SQL para scripts o migraciones si se requieren
COPY database/ ./database/

# Usar usuario sin privilegios por seguridad
USER node

EXPOSE 3000

CMD ["node", "dist/main.js"]
