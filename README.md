<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.ibb.co/5hCHs54H/lead-hub-high-resolution-logo-modified.png" alt="Project logo"></a>
</p>

<h3 align="center">LeadHub Service</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/Blue-Davinci/leadhub-service)
[![GitHub Issues](https://img.shields.io/github/issues/Blue-Davinci/leadhub-service.svg)](https://github.com/Blue-Davinci/leadhub-service/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/Blue-Davinci/leadhub-service.svg)](https://github.com/Blue-Davinci/leadhub-service/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>

---

<p align="center"> An real source african assignment
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [DevOps & Deployment](#deployment)
- [Usage](#usage)
- [API Documentation](#api_docs)
- [Testing](#testing)
- [Built Using](#built_using)
- [Authors](#authors)
- [Documentation](#documentation)

## 🧐 About <a name = "about"></a>

**LeadHub Service** is the foundational backend system for Real Sources Africa’s LeadHub platform. It supports multi-tenancy, secure lead management, and administrative oversight.  
Each tenant (e.g., government agency, investment authority) can create, manage, and view only their trade leads, with strict data isolation.  
An admin interface allows for onboarding new tenants and system-wide statistics reporting.


## 🏁 Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [deployment](#deployment) for notes on how to deploy the project on a live system.

### Prerequisites

```bash
- Go 1.20+
- Docker & Docker Compose
- PostgreSQL 14+
- Redis
- GNU Make (optional, for scripted workflows)
```

### Installing

- Clone the repo:

```bash
git clone https://github.com/Blue-Davinci/leadhub-service.git
cd leadhub-service
```
- Set up environment variables:

```bash
cp .env.example .env
```

- Apply database migrations:

```bash
go run cmd/migrate.go up
```

## 🔧 Running the tests <a name = "tests"></a>

Explain how to run the automated tests for this system.

### Break down into end to end tests

Run unit tests

```bash
go test ./...
```
_Integration and e2e test instructions coming soon._

### And coding style tests

_coming soon_

```bash
echo "we coming"
```

## 🎈 Usage <a name="usage"></a>

Once running locally:
```bash
API base URL: http://localhost:4000/v1

Health check: GET /v1/health

Trade leads: GET /v1/trade_leads/ (Bearer token required)
```

## 🚀 DevOps & Deployment <a name = "deployment"></a>

### Quick Start
```bash
# Development environment
make docker/dev

# Production deployment  
make deploy/production
```

### CI/CD Pipeline
- **Automated Testing**: Unit, integration, and security tests
- **Container Security**: Vulnerability scanning with Trivy
- **Multi-environment**: Staging (development branch) and Production (releases)
- **Health Monitoring**: Automated health checks and rollback

### Documentation
- **[Complete Deployment Guide](./docs/DEPLOYMENT.md)** - Comprehensive deployment procedures
- **[DevOps Guide](./docs/DEVOPS.md)** - Infrastructure and operational procedures  
- **[Implementation Summary](./docs/IMPLEMENTATION_SUMMARY.md)** - Technical implementation details

## 🧪 Testing <a name = "testing"></a>

```bash
# Run all tests
make test/all

# Test coverage report
./test.sh
```

**Test Coverage:**
- Multi-tenant security validation
- Authentication and authorization
- Rate limiting and panic recovery
- Business logic validation
- Financial precision testing

## 📚 API Documentation <a name = "api_docs"></a>

### Authentication
```bash
# Create user
POST /v1/api/
{
  "name": "John Doe",
  "email": "john@company.com", 
  "password": "securepassword"
}

# Get API token
POST /v1/api/authentication
{
  "email": "john@company.com",
  "password": "securepassword"
}
```

### Trade Leads Management
```bash
# Create trade lead (authenticated)
POST /v1/trade_leads/
Authorization: Bearer <token>
{
  "title": "Software Development Project",
  "description": "Mobile app development",
  "value": 50000.00
}

# Get tenant's trade leads
GET /v1/trade_leads/
Authorization: Bearer <token>
```

## ⛏️ Built Using <a name = "built_using"></a>

- **[Go 1.23](https://golang.org)** – Backend language with robust concurrency
- **[PostgreSQL 16](https://postgresql.org)** – Relational database with JSON support
- **[NGINX](https://nginx.org)** – Reverse proxy and load balancer
- **[Docker](https://docker.com)** – Containerization platform
- **[GitHub Actions](https://github.com/features/actions)** – CI/CD automation
- **[Goose](https://github.com/pressly/goose)** – Database migration tool

## ✍️ Authors <a name = "authors"></a>

- [@blue-davinci](https://github.com/Blue-Davinci) - Lead Developer & DevOps Engineer

## 📖 Documentation <a name = "documentation"></a>

### Core Documentation
- **[Deployment Guide](./docs/DEPLOYMENT.md)** - Complete deployment procedures
- **[DevOps Guide](./docs/DEVOPS.md)** - Infrastructure management
- **[Implementation Summary](./docs/IMPLEMENTATION_SUMMARY.md)** - Technical overview

### Development
- **[Test Guide](./test.sh)** - Automated testing procedures
- **[Migration Scripts](./scripts/)** - Database and deployment automation
- **[Environment Configs](./configs/)** - Environment-specific configurations

### Security & Compliance
- Multi-tenant data isolation at application level
- Bearer token based authentication with API key support
- Rate limiting and input validation
- Container security with vulnerability scanning
