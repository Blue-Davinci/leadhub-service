# 🗄️ Adminer Database Administration Tool

## What is Adminer?
Adminer is a web-based database administration tool that provides a user-friendly interface for managing PostgreSQL (and other) databases.

## Purpose in LeadHub Service:
- **Database Browsing**: View tables, data, and structure
- **Query Execution**: Run SQL queries directly 
- **Data Management**: Insert, update, delete records
- **Schema Management**: Create/modify tables and relationships
- **Import/Export**: Backup and restore data
- **Debugging**: Troubleshoot database issues

## Access Information:
- **URL**: http://localhost:8080
- **Database**: leadhub  
- **Username**: leadhub
- **Password**: leadhub_staging_password (for staging)
- **Server**: postgres

## Relationship to Other Services:
- **Grafana**: Independent - Grafana reads metrics, not database data
- **Prometheus**: Independent - Prometheus scrapes metrics from API
- **API**: Adminer and API both connect to same PostgreSQL database

## When to Use:
- Development and staging environments
- Debugging database issues
- Manual data inspection
- Running database queries
- Database schema exploration

⚠️ **Security Note**: Disable in production environments for security!
