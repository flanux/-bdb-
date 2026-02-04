-- ============================================
-- Account Service Database Schema
-- ============================================

\c account_db;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Account Types Enum
CREATE TYPE account_type AS ENUM ('SAVINGS', 'CHECKING', 'FIXED_DEPOSIT', 'CURRENT', 'SALARY');

-- Account Status Enum
CREATE TYPE account_status AS ENUM ('ACTIVE', 'INACTIVE', 'FROZEN', 'CLOSED', 'SUSPENDED');

-- Accounts Table
CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    account_type account_type NOT NULL,
    account_status account_status DEFAULT 'ACTIVE',
    balance DECIMAL(19, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    interest_rate DECIMAL(5, 2) DEFAULT 0.00,
    overdraft_limit DECIMAL(19, 2) DEFAULT 0.00,
    branch_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    last_transaction_date TIMESTAMP,
    closure_date TIMESTAMP,
    closure_reason TEXT,
    
    CONSTRAINT positive_balance CHECK (balance >= -overdraft_limit),
    CONSTRAINT valid_interest_rate CHECK (interest_rate >= 0 AND interest_rate <= 100)
);

-- Account Beneficiaries
CREATE TABLE account_beneficiaries (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    beneficiary_name VARCHAR(255) NOT NULL,
    beneficiary_relationship VARCHAR(50),
    beneficiary_percentage DECIMAL(5, 2) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_percentage CHECK (beneficiary_percentage > 0 AND beneficiary_percentage <= 100)
);

-- Account Statements
CREATE TABLE account_statements (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    statement_date DATE NOT NULL,
    opening_balance DECIMAL(19, 2) NOT NULL,
    closing_balance DECIMAL(19, 2) NOT NULL,
    total_credits DECIMAL(19, 2) DEFAULT 0.00,
    total_debits DECIMAL(19, 2) DEFAULT 0.00,
    transaction_count INT DEFAULT 0,
    file_path VARCHAR(500),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(account_id, statement_date)
);

-- Account Holds (Temporary freezes on amounts)
CREATE TABLE account_holds (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    hold_amount DECIMAL(19, 2) NOT NULL,
    hold_reason VARCHAR(255) NOT NULL,
    hold_type VARCHAR(50) NOT NULL,
    reference_number VARCHAR(100),
    hold_status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_by VARCHAR(100),
    
    CONSTRAINT positive_hold_amount CHECK (hold_amount > 0)
);

-- Indexes for performance
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
CREATE INDEX idx_accounts_status ON accounts(account_status);
CREATE INDEX idx_accounts_type ON accounts(account_type);
CREATE INDEX idx_account_beneficiaries_account_id ON account_beneficiaries(account_id);
CREATE INDEX idx_account_statements_account_id ON account_statements(account_id);
CREATE INDEX idx_account_statements_date ON account_statements(statement_date);
CREATE INDEX idx_account_holds_account_id ON account_holds(account_id);
CREATE INDEX idx_account_holds_status ON account_holds(hold_status);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for accounts table
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO account_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO account_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Account database schema created successfully!'
