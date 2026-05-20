# --- Stage 1: Build static executable ---
FROM golang:1.25-alpine AS builder

# SQLite requires CGO, so we install build-base (GCC, libc-dev, etc.)
RUN apk add --no-cache build-base

WORKDIR /app

# Copy dependency files first for caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the entire source code
COPY . .

# Compile the Go binary with CGO enabled. 
# We build a fully statically compiled binary for Alpine.
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags "-extldflags '-static'" -o ilkf-backend cmd/api/main.go

# --- Stage 2: Create runtime container ---
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Create data directory for persistent SQLite database volume mounts
RUN mkdir -p /app/data

# Copy the compiled statically linked binary
COPY --from=builder /app/ilkf-backend .

# Copy the SQL migration schema so the auto-migration startup logic can find it
COPY --from=builder /app/db/schema.sql ./db/schema.sql

# Set default production environment variables
ENV APP_ENV=production
ENV PORT=8080
ENV DATABASE_PATH=/app/data/ilkf.db

# Expose Go server port
EXPOSE 8080

# Command to run the backend application
CMD ["./ilkf-backend"]
