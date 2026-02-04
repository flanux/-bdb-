-- ============================================
-- Flanux Microservices Database Initialization
-- ============================================

-- Create databases for each microservice
CREATE DATABASE account_db;
CREATE DATABASE customer_db;
CREATE DATABASE loan_db;
CREATE DATABASE card_db;
CREATE DATABASE transaction_db;
CREATE DATABASE ledger_db;
CREATE DATABASE notification_db;
CREATE DATABASE reporting_db;
CREATE DATABASE auth_db;

-- Create service users with appropriate permissions
CREATE USER account_user WITH PASSWORD 'account_pass_2024';
CREATE USER customer_user WITH PASSWORD 'customer_pass_2024';
CREATE USER loan_user WITH PASSWORD 'loan_pass_2024';
CREATE USER card_user WITH PASSWORD 'card_pass_2024';
CREATE USER transaction_user WITH PASSWORD 'transaction_pass_2024';
CREATE USER ledger_user WITH PASSWORD 'ledger_pass_2024';
CREATE USER notification_user WITH PASSWORD 'notification_pass_2024';
CREATE USER reporting_user WITH PASSWORD 'reporting_pass_2024';
CREATE USER auth_user WITH PASSWORD 'auth_pass_2024';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE account_db TO account_user;
GRANT ALL PRIVILEGES ON DATABASE customer_db TO customer_user;
GRANT ALL PRIVILEGES ON DATABASE loan_db TO loan_user;
GRANT ALL PRIVILEGES ON DATABASE card_db TO card_user;
GRANT ALL PRIVILEGES ON DATABASE transaction_db TO transaction_user;
GRANT ALL PRIVILEGES ON DATABASE ledger_db TO ledger_user;
GRANT ALL PRIVILEGES ON DATABASE notification_db TO notification_user;
GRANT ALL PRIVILEGES ON DATABASE reporting_db TO reporting_user;
GRANT ALL PRIVILEGES ON DATABASE auth_db TO auth_user;

-- Create read-only user for reporting/analytics
CREATE USER readonly_user WITH PASSWORD 'readonly_pass_2024';
GRANT CONNECT ON DATABASE account_db TO readonly_user;
GRANT CONNECT ON DATABASE customer_db TO readonly_user;
GRANT CONNECT ON DATABASE loan_db TO readonly_user;
GRANT CONNECT ON DATABASE card_db TO readonly_user;
GRANT CONNECT ON DATABASE transaction_db TO readonly_user;
GRANT CONNECT ON DATABASE ledger_db TO readonly_user;

\echo 'All databases and users created successfully!'
