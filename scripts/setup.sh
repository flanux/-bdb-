#!/bin/bash

# ============================================
# Flanux Database Setup - Quick Start Script
# ============================================

echo "🚀 Starting Flanux Database Setup..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"
echo ""

# Navigate to docker directory
cd docker

echo "📦 Starting PostgreSQL, PgAdmin, and Redis..."
docker-compose up -d

echo ""
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10

# Check if PostgreSQL is ready
until docker exec flanux-postgres pg_isready -U flanux_admin &>/dev/null; do
    echo "⏳ Still waiting for PostgreSQL..."
    sleep 2
done

echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
echo ""

# List databases
echo "📊 Checking created databases..."
docker exec flanux-postgres psql -U flanux_admin -d postgres -c "\l" | grep -E "(account_db|customer_db|loan_db|card_db|transaction_db|ledger_db|notification_db|reporting_db|auth_db)"

echo ""
echo -e "${GREEN}✅ Database setup complete!${NC}"
echo ""
echo "📝 Connection Details:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Admin User: flanux_admin"
echo "  Admin Password: flanux_secure_password_2024"
echo ""
echo "🌐 PgAdmin Access:"
echo "  URL: http://localhost:5050"
echo "  Email: admin@flanux.com"
echo "  Password: admin123"
echo ""
echo "📊 Redis:"
echo "  Host: localhost"
echo "  Port: 6379"
echo ""
echo -e "${YELLOW}⚠️  Remember to change passwords in production!${NC}"
echo ""
echo "🎉 All services are running! You can now integrate with your microservices."
