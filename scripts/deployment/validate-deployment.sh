#!/bin/bash

# ===============================================
# LeadHub Service - Deployment Validation Script
# ===============================================
# This script validates that all services are running correctly

echo "🚀 LeadHub Service - Deployment Validation"
echo "==========================================="
echo

# Check Docker containers status
echo "📦 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep leadhub
echo

# Test API Health
echo "🏥 API Health Check:"
API_HEALTH=$(curl -s http://localhost/v1/health)
if [ $? -eq 0 ]; then
    echo "API Health: OK"
    echo " Response: $API_HEALTH"
else
    echo "API Health: FAILED"
fi
echo

# Test API Debug Endpoint
echo "🔍 API Debug Endpoint:"
DEBUG_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/v1/debug/vars)
if [ "$DEBUG_RESPONSE" = "200" ]; then
    echo "Debug Endpoint: OK (HTTP $DEBUG_RESPONSE)"
else
    echo "Debug Endpoint: FAILED (HTTP $DEBUG_RESPONSE)"
fi
echo

# Test Database Connection via Adminer
echo "🗄️  Database Access (Adminer):"
ADMINER_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$ADMINER_RESPONSE" = "200" ]; then
    echo "Adminer: OK (HTTP $ADMINER_RESPONSE) - Available at http://localhost:8080"
else
    echo "Adminer: FAILED (HTTP $ADMINER_RESPONSE)"
fi
echo

# Test Prometheus
echo "Prometheus Monitoring:"
PROMETHEUS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090)
if [ "$PROMETHEUS_RESPONSE" = "200" ]; then
    echo "Prometheus: OK (HTTP $PROMETHEUS_RESPONSE) - Available at http://localhost:9090"
else
    echo "Prometheus: FAILED (HTTP $PROMETHEUS_RESPONSE)"
fi
echo

# Test Grafana
echo "Grafana Dashboard:"
GRAFANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$GRAFANA_RESPONSE" = "200" ]; then
    echo "Grafana: OK (HTTP $GRAFANA_RESPONSE) - Available at http://localhost:3000"
else
    echo "Grafana: FAILED (HTTP $GRAFANA_RESPONSE)"
fi
echo

# Summary
echo "> Deployment Summary:"
echo "   • API: http://localhost/v1/health"
echo "   • Database Admin: http://localhost:8080"
echo "   • Monitoring: http://localhost:9090"
echo "   • Analytics: http://localhost:3000"
echo "   • Environment: Staging"
echo
echo "> Deployment validation completed!"
