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

<p align="center"> Few lines describing your project.
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Deployment](#deployment)
- [Usage](#usage)
- [Built Using](#built_using)
- [TODO](../TODO.md)
- [Contributing](../CONTRIBUTING.md)
- [Authors](#authors)
- [Acknowledgments](#acknowledgement)

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
API base URL: http://localhost:8080/api/v1

Health check: GET /api/v1/health

Tenant leads: GET /api/v1/leads/ (Bearer token required)
```

## 🚀 Deployment <a name = "deployment"></a>

Preliminary instructions (Still in development)
```bash
./deploy.sh leadhub-service:latest
```
This script will handle:

- Docker image pulling
- Service restart
- Health check validation
- Loading configuration from .env

CI/CD pipeline via GitHub Actions automates linting, testing, building, vulnerability scanning, and deployment.

## ⛏️ Built Using <a name = "built_using"></a>

- [Go]() – Backend language
- [PostgreSQL]() – Relational database
- [Redis]() – Caching for stats
- [Docker]() – Containerization
- [GitHub Actions]() – CI/CD
- [Goose]() – Database migrations

## ✍️ Authors <a name = "authors"></a>

- [@blue-davinci](https://github.com/kylelobo) - Idea & Initial work

See also the list of [contributors](https://github.com/kylelobo/The-Documentation-Compendium/contributors) who participated in this project.

## 🎉 Acknowledgements <a name = "acknowledgement"></a>

- Real Sources Africa for the assignment context
- Go, Redis, PostgreSQL, and Docker maintainers
