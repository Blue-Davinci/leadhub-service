# =============================================================================
# LeadHub Service - Production Dockerfile
# =============================================================================
# Multi-stage build for optimal size and security
# Stage 1: Build the Go application
# Stage 2: Create minimal runtime image

FROM golang:1.24.4-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Create non-root user for security
RUN adduser -D -g '' appuser

# Copy go.mod and go.sum first (better caching)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the application with optimizations
# -ldflags='-w -s' strips debug info for smaller binary
# CGO_ENABLED=0 for static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o leadhub-api ./cmd/api

# =============================================================================
# Stage 2: Create minimal runtime image
FROM scratch

# Import from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/passwd /etc/passwd

# Copy binary from builder stage
COPY --from=builder /app/leadhub-api /leadhub-api

# Copy email templates for mailer functionality
COPY --from=builder /app/internal/mailer/templates /templates

# Use non-root user for security
USER appuser

# Expose port (configurable via environment)
EXPOSE 4000

# Health check using our health endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/leadhub-api", "healthcheck"] || exit 1

# Set default environment variables
ENV PORT=4000
ENV ENV=production

# Set entrypoint
ENTRYPOINT ["/leadhub-api"]

# Metadata labels for better container management
LABEL maintainer="Blue-Davinci <blue.davinci@leadhub-service.com>"
LABEL org.opencontainers.image.title="LeadHub Service"
LABEL org.opencontainers.image.description="Multi-tenant SaaS REST API for lead management"
LABEL org.opencontainers.image.source="https://github.com/Blue-Davinci/leadhub-service"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="Real Sources Africa"
