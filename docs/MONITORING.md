# 📊 LeadHub Service - Monitoring Guide

## Overview

LeadHub Service includes comprehensive monitoring capabilities using Prometheus and Grafana for metrics collection, visualization, and alerting.

## Monitoring Stack

### Components
- **Prometheus**: Metrics collection and time-series database
- **Grafana**: Dashboard visualization and alerting
- **NGINX**: Reverse proxy with monitoring integration
- **LeadHub API**: Application health checks and service metrics

## 🚀 Quick Start

### Access Monitoring Services

#### Grafana Dashboard
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: Set via environment variables (see credentials section below)
- **Purpose**: View dashboards, metrics visualization, and alerts

#### Prometheus Metrics
- **URL**: http://localhost:9090
- **Purpose**: Raw metrics collection, query interface, and target monitoring

## 🔐 Credentials Configuration

### Environment Variables
Monitoring credentials are managed through environment files for security:

#### Staging Environment (`.env.staging`)
```bash
# Grafana Configuration (Monitoring Dashboard)
# Change these credentials for production use
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=leadhub_grafana_staging_2025
```

#### Production Environment (`.env.production`)
```bash
# Grafana Configuration (Monitoring Dashboard)
# IMPORTANT: Set strong credentials for production
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_secure_grafana_password
```

### Security Best Practices
- ✅ **No Hardcoded Passwords**: Credentials stored in environment files
- ✅ **Environment-Specific**: Different passwords for staging vs production  
- ✅ **Gitignored**: Environment files excluded from version control
- ✅ **Configurable**: Easy to change without modifying Docker configurations

## 📈 Available Dashboards

### LeadHub Monitoring Dashboard
- **Service Health Status**: Shows if the LeadHub API is responding
- **Prometheus Targets**: Displays all monitored services and their status
- **Real-time Updates**: Auto-refreshes every 5 seconds

## 🔧 Configuration Files

### Prometheus Configuration
- **File**: `monitoring/prometheus.yml`
- **Purpose**: Defines metrics collection targets and scrape intervals
- **Targets**: LeadHub API health checks, Prometheus self-monitoring

### Grafana Configuration
- **Datasources**: `monitoring/grafana/datasources/prometheus.yml`
- **Dashboards**: `monitoring/grafana/dashboards/leadhub.json`
- **Provisioning**: Automatically configures Prometheus as data source

## 🚀 Deployment

### Staging Deployment
```bash
# Deploy with monitoring stack
./scripts.sh deploy staging

# Access Grafana
# URL: http://localhost:3000
# Credentials: admin / leadhub_grafana_staging_2025
```

### Production Deployment  
```bash
# Set secure credentials in .env.production first
GRAFANA_ADMIN_PASSWORD=your_very_secure_password

# Deploy to production
./scripts.sh deploy production
```

## 🔍 Monitoring Capabilities

### Health Monitoring
- **API Health**: Continuous monitoring of `/v1/health` endpoint
- **Service Discovery**: Automatic detection of service availability
- **Status Tracking**: Up/down status for all components

### Metrics Collection
- **Service Uptime**: Track service availability over time
- **Response Monitoring**: Basic response time tracking
- **Target Health**: Monitor all Prometheus scrape targets

## 🛠 Troubleshooting

### Common Issues

#### Grafana Login Issues
```bash
# Check Grafana logs
docker logs leadhub-grafana-staging

# Reset Grafana admin password
docker-compose -f docker-compose.staging.yml restart grafana
```

#### Missing Dashboards
```bash
# Restart Grafana to reload provisioning
docker-compose -f docker-compose.staging.yml restart grafana

# Check dashboard provisioning logs
docker logs leadhub-grafana-staging | grep dashboard
```

#### Prometheus Connection Issues
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Restart Prometheus
docker-compose -f docker-compose.staging.yml restart prometheus
```

## 📚 Related Documentation

- **[Deployment Guide](./DEPLOYMENT.md)** - Complete deployment procedures
- **[DevOps Guide](./DEVOPS.md)** - Infrastructure management 
- **[Script Organization](./SCRIPT_ORGANIZATION.md)** - Automation scripts
- **[Adminer Guide](./ADMINER_GUIDE.md)** - Database administration

## 🔮 Future Enhancements

- Advanced application metrics (request rates, response times)
- Alerting rules for service outages
- Dashboard for business metrics (user activity, lead creation rates)
- Integration with external monitoring services
- Performance monitoring and APM integration
