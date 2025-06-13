# LeadHub Service - DevOps & Deployment Guide

This guide covers containerization, CI/CD pipeline, and deployment procedures for the LeadHub multi-tenant SaaS REST API.

## 🚀 Quick Start

### Local Development
```bash
# Start local development environment
docker-compose up -d

# Run database migrations
./scripts/migrate.sh development up

# Run tests
./test.sh

# Access the application
curl http://localhost:4000/v1/health
```

### Production Deployment
```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production (requires release)
./scripts/deploy.sh production latest
```

## 🏗️ Architecture Overview

### Production Stack
- **Application**: Go REST API with multi-tenant architecture
- **Database**: PostgreSQL with connection pooling
- **Reverse Proxy**: NGINX for load balancing and SSL termination
- **Monitoring**: Prometheus metrics and health checks
- **Migrations**: Goose for database schema management

### Why NGINX in Production?

1. **Performance Benefits**
   - Load balancing across multiple app instances
   - Static file serving without hitting Go app
   - Gzip compression for reduced bandwidth
   - Connection pooling and keep-alive optimization

2. **Security Features**
   - SSL/TLS termination and certificate management
   - Request filtering and rate limiting
   - Security headers (HSTS, CSP, X-Frame-Options)
   - Protection against common web attacks

3. **Operational Benefits**
   - Zero-downtime deployments
   - Health check integration
   - Centralized logging and metrics
   - Response caching capabilities

## 🐳 Containerization

### Multi-Stage Dockerfile
The production Dockerfile uses multi-stage builds for optimal image size:

1. **Build Stage**: Compiles the Go application
2. **Runtime Stage**: Minimal alpine image with just the binary

### Docker Compose Services
- `api`: Go application instances (scalable)
- `nginx`: Reverse proxy and load balancer
- `db`: PostgreSQL database with persistent storage
- `prometheus`: Metrics collection
- `grafana`: Metrics visualization

## 🔄 CI/CD Pipeline

### Workflow Stages

1. **Test Phase**
   - Unit and integration tests
   - Race condition detection
   - Code coverage reporting
   - Multiple Go version testing

2. **Security Phase**
   - Static code analysis with gosec
   - Container vulnerability scanning with Trivy
   - Dependency scanning

3. **Build Phase**
   - Docker image building
   - Image tagging and metadata
   - Registry push (GitHub Container Registry)

4. **Deploy Phase**
   - Staging deployment (on develop branch)
   - Production deployment (on release)
   - Health check validation

### Triggers
- **Push to main/develop**: Full pipeline with deployment
- **Pull requests**: Tests and build only
- **Releases**: Production deployment

## 📊 Database Migrations

### Using Goose
The project uses Goose for database migrations:

```bash
# Apply all pending migrations
./scripts/migrate.sh production up

# Rollback one migration
./scripts/migrate.sh production down

# Check migration status
./scripts/migrate.sh production status

# Create new migration
./scripts/migrate.sh development create add_new_table
```

### Migration Files
Located in `internal/sql/schema/`:
- `001_create_table_tenants.sql`
- `002_create_users.sql`
- `003_create_user_apikey.sql`
- `004_create_permissions_table.sql`
- `005_create_table_trade_leads.sql`

## 🔧 Environment Configuration

### Development
- Relaxed security settings
- Debug logging enabled
- Hot reloading with Air
- Local SMTP testing

### Staging
- Production-like environment
- Mailtrap for email testing
- Detailed logging for debugging
- Permissive CORS for testing

### Production
- Strict security settings
- Real SMTP provider (SendGrid)
- Optimized database pools
- Minimal logging for performance

## 📝 Deployment Procedures

### Staging Deployment
Triggered automatically on push to `develop` branch:
1. Tests pass
2. Security scans complete
3. Docker image built and scanned
4. Deployed to staging environment
5. Health checks verify deployment

### Production Deployment
Triggered on GitHub releases:
1. All staging validations pass
2. Production database migrations
3. Blue-green deployment strategy
4. Health check validation
5. Rollback capability if issues

### Manual Deployment
```bash
# Deploy specific version to staging
./scripts/deploy.sh staging v1.2.3

# Emergency production deployment
./scripts/deploy.sh production latest
```

## 🔍 Monitoring & Observability

### Health Checks
- Application health: `/v1/health`
- Database connectivity
- External service dependencies

### Metrics
- Request rates and latency
- Database connection pool stats
- Error rates by endpoint
- Business metrics (lead creation, etc.)

### Logging
- Structured JSON logging
- Request/response logging
- Error tracking and alerting
- Performance monitoring

## 🛡️ Security Considerations

### Application Security
- JWT-based authentication
- Role-based access control (RBAC)
- Multi-tenant data isolation
- Input validation and sanitization

### Infrastructure Security
- Container vulnerability scanning
- Secrets management
- Network segmentation
- Regular security updates

### Deployment Security
- Encrypted secrets in CI/CD
- Image signing and verification
- Least privilege access
- Audit logging

## 🚨 Troubleshooting

### Common Issues

1. **Migration Failures**
   ```bash
   # Check current status
   ./scripts/migrate.sh production status
   
   # Manual rollback if needed
   ./scripts/migrate.sh production down
   ```

2. **Container Health Issues**
   ```bash
   # Check service logs
   docker-compose -f docker-compose.prod.yml logs api
   
   # Restart specific service
   docker-compose -f docker-compose.prod.yml restart api
   ```

3. **Database Connection Issues**
   ```bash
   # Test database connectivity
   docker-compose -f docker-compose.prod.yml exec db psql -U leadhub -d leadhub
   ```

### Recovery Procedures
- Automated rollback on health check failure
- Database backup and restore procedures
- Emergency contact and escalation

## 📚 Additional Resources

- [Go Application Documentation](./README.md)
- [API Documentation](./docs/api.md)
- [Database Schema](./internal/sql/schema/)
- [Test Coverage Reports](./coverage.html)

## 🤝 Contributing

1. Create feature branch from `develop`
2. Run tests locally: `./test.sh`
3. Submit pull request
4. CI/CD pipeline validates changes
5. Merge to `develop` for staging deployment
6. Create release for production deployment
