#!/bin/bash
# ===============================================
# LeadHub Service - Script Management Center
# ===============================================
# This script provides easy access to all project scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🚀 LeadHub Service                                  ║"
    echo "║                          Script Management Center By:Blue-Davinci            ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_category() {
    echo -e "\n${CYAN} $1${NC}"
    echo "────────────────────────────────────────────────────────────"
}

show_help() {
    show_header
    
    show_category "DEPLOYMENT SCRIPTS"
    echo -e "${GREEN}  ./scripts/deployment/deploy.sh [staging|production]${NC} - Deploy application"
    echo -e "${GREEN}  ./scripts/deployment/validate-deployment.sh${NC}       - Validate deployment"
    echo -e "${GREEN}  ./scripts/deployment/teardown.sh [environment]${NC}    - Tear down environment"
    
    show_category "DEVELOPMENT SCRIPTS"  
    echo -e "${GREEN}  ./scripts/development/dev.sh [--reset]${NC}            - Start development environment"
    
    show_category "DATABASE SCRIPTS"
    echo -e "${GREEN}  ./scripts/database/reset-db.sh${NC}                    - Reset database to clean state"
    echo -e "${GREEN}  ./scripts/database/migrate.sh${NC}                     - Run database migrations"
    echo -e "${GREEN}  ./scripts/database/add-user-permissions.sh${NC}       - Add user permissions"
    echo -e "${GREEN}  ./scripts/database/generate-docker-init.sh${NC}       - Generate Docker init files (auto-run during deploy)"
    
    show_category "TESTING SCRIPTS"
    echo -e "${GREEN}  ./scripts/testing/test.sh${NC}                         - Run full test suite"
    echo -e "${GREEN}  ./scripts/testing/test-db-connection.sh [env]${NC}     - Test database connectivity"
    echo -e "${GREEN}  ./scripts/testing/test-complete-setup.sh${NC}          - Test complete setup"
    echo -e "${GREEN}  ./scripts/testing/test-deployment.sh${NC}              - Test deployment"
    
    show_category "MAINTENANCE SCRIPTS"
    echo -e "${GREEN}  ./scripts/maintenance/quick-fix.sh${NC}                - Quick fix for common issues"
    echo -e "${GREEN}  ./scripts/maintenance/healthcheck.sh${NC}              - System health check"
    
    show_category "COMMON USAGE EXAMPLES"
    echo -e "${YELLOW}  # Start development environment${NC}"
    echo -e "  ./scripts/development/dev.sh"
    echo
    echo -e "${YELLOW}  # Deploy to staging${NC}" 
    echo -e "  ./scripts/deployment/deploy.sh staging"
    echo
    echo -e "${YELLOW}  # Run tests${NC}"
    echo -e "  ./scripts/testing/test.sh"
    echo
    echo -e "${YELLOW}  # Reset database${NC}"
    echo -e "  ./scripts/database/reset-db.sh"
    echo
    echo -e "${YELLOW}  # Tear down staging${NC}"
    echo -e "  ./scripts/deployment/teardown.sh staging"
    echo
}

# If no arguments provided, show help
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Handle script execution
case "$1" in
    "dev"|"development")
        shift
        ./scripts/development/dev.sh "$@"
        ;;
    "deploy")
        shift
        ./scripts/deployment/deploy.sh "$@"
        ;;
    "test")
        shift
        ./scripts/testing/test.sh "$@"
        ;;
    "teardown")
        shift
        ./scripts/deployment/teardown.sh "$@"
        ;;
    "validate")
        ./scripts/deployment/validate-deployment.sh
        ;;
    "reset-db")
        ./scripts/database/reset-db.sh
        ;;
    "generate")
        ./scripts/database/generate-docker-init.sh
        ;;
    "quick-fix")
        ./scripts/maintenance/quick-fix.sh
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Run ${GREEN}./scripts.sh help${NC} for usage information"
        exit 1
        ;;
esac
