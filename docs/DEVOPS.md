# LeadHub Service - DevOps & Deployment Guide

This guide covers containerization, CI/CD pipeline, and deployment procedures for the LeadHub multi-tenant SaaS REST API.

## 🚀 Quick Start

### Local Development
```bash
# Start local development environment
./scripts.sh dev

# Or with database reset
./scripts.sh dev --reset

# Run tests
./scripts.sh test

# Access the application
curl http://localhost:4000/v1/health
```

### Production Deployment
```bash
# Generate Docker initialization files
./scripts.sh generate

# Deploy to staging
./scripts.sh deploy staging

# Deploy to production
./scripts.sh deploy production

# Validate deployment
./scripts.sh validate
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
- `prometheus`: Metrics collection and monitoring
- `grafana`: Dashboard visualization and alerting

### Monitoring Stack
- **Prometheus**: http://localhost:9090 - Metrics collection
- **Grafana**: http://localhost:3000 - Dashboard visualization
- **Credentials**: Managed via environment variables (see [Monitoring Guide](./MONITORING.md))
- **Security**: No hardcoded passwords, environment-specific configuration

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

## 📊 Database Schema Management

### Single Source of Truth Workflow
The project uses an automated schema management system:

```bash
# Primary source: /internal/sql/schema/ (Goose migrations)
# Auto-generated: /internal/sql/docker-init/ (Docker init files)

# Generate Docker init files from schema
./scripts.sh generate

# Deploy with updated schema
./scripts.sh deploy staging
```

### Local Development with Goose
```bash
# Apply all pending migrations
./scripts/database/migrate.sh production up

# Rollback one migration  
./scripts/database/migrate.sh production down

# Check migration status
./scripts/database/migrate.sh production status

# Create new migration
./scripts/database/migrate.sh development create add_new_table
```

### Schema Files
**Primary Source** - `/internal/sql/schema/`:
- `001_create_table_tenants.sql`
- `002_create_users.sql`
- `003_create_user_apikey.sql`
- `004_create_permissions_table.sql`
- `005_create_table_trade_leads.sql`

**Auto-Generated** - `/internal/sql/docker-init/`:
- Clean SQL files for PostgreSQL container initialization
- Generated automatically from Goose migrations
- No down migrations or Goose directives

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

### Script-Based Deployment
All deployments use the centralized script management system:

```bash
# View all available commands
./scripts.sh help

# Generate Docker initialization files
./scripts.sh generate

# Deploy to staging
./scripts.sh deploy staging

# Deploy to production  
./scripts.sh deploy production

# Validate deployment
./scripts.sh validate

# Teardown environment
./scripts.sh teardown staging
```

### Staging Deployment
Triggered automatically on push to `develop` branch:
1. Tests pass
2. Security scans complete
3. Docker image built and scanned
4. Schema files generated automatically
5. Deployed to staging environment
6. Health checks verify deployment

### Production Deployment
Triggered on GitHub releases:
1. All staging validations pass
2. Automated schema generation
3. Production database initialization
4. Blue-green deployment strategy
5. Health check validation
6. Rollback capability if issues

### Manual Deployment
```bash
# Deploy to staging with script manager
./scripts.sh deploy staging

# Deploy to production with script manager
./scripts.sh deploy production

# Or use direct scripts
./scripts/deployment/deploy.sh staging
./scripts/deployment/deploy.sh production
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
