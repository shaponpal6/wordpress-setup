#!/bin/bash

# WordPress Services Restart Script
# Safely restarts services without impacting live data
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}WordPress Services Restart Script${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. This is not recommended for production."
fi

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Function to restart a specific environment
restart_environment() {
    local env_name=$1
    local compose_file=$2
    
    echo ""
    print_status "Restarting $env_name environment..."
    
    # Check if the environment is running
    if docker-compose -f "$compose_file" ps | grep -q "Up"; then
        print_status "Stopping $env_name services gracefully..."
        docker-compose -f "$compose_file" stop
        
        # Wait a bit for services to stop
        sleep 5
        
        print_status "Starting $env_name services..."
        docker-compose -f "$compose_file" up -d
    else
        print_warning "$env_name environment is not currently running. Starting it now..."
        docker-compose -f "$compose_file" up -d
    fi
    
    # Wait for services to be ready
    sleep 10
    
    # Verify services are running
    print_status "Verifying $env_name services are running..."
    docker-compose -f "$compose_file" ps
}

# Main script logic
if [ $# -eq 0 ]; then
    echo "Usage: $0 [live|staging|all]"
    echo "  live   - Restart only live environment"
    echo "  staging - Restart only staging environment"
    echo "  all    - Restart both live and staging environments (default)"
    echo ""
    read -p "No environment specified. Restart both live and staging? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_environment "Live" "docker-compose.live.yml"
        restart_environment "Staging" "docker-compose.staging.yml"
    else
        exit 0
    fi
elif [ "$1" = "live" ]; then
    restart_environment "Live" "docker-compose.live.yml"
elif [ "$1" = "staging" ]; then
    restart_environment "Staging" "docker-compose.staging.yml"
elif [ "$1" = "all" ]; then
    restart_environment "Live" "docker-compose.live.yml"
    restart_environment "Staging" "docker-compose.staging.yml"
else
    print_error "Invalid option. Use 'live', 'staging', or 'all'."
    exit 1
fi

# Restart logging services if they exist
if [ -f "docker-compose.logging.yml" ]; then
    print_status "Restarting logging services..."
    docker-compose -f docker-compose.logging.yml restart || print_warning "Could not restart logging services"
fi

echo ""
print_status "Services restart completed!"
echo ""
print_status "Useful commands:"
echo -e "  ${YELLOW}./health-check-live.sh${NC}    - Check live environment health"
echo -e "  ${YELLOW}./health-check-staging.sh${NC} - Check staging environment health"
echo -e "  ${YELLOW}./monitor.sh${NC}              - Monitor all services"
echo ""
print_status "Services have been restarted safely. Data volumes were preserved during restart."