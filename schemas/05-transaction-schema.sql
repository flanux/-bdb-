-- ============================================
-- Transaction Service Database Schema
-- ============================================

\c transaction_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Transaction Type Enum
CREATE TYPE transaction_type AS ENUM (
    'DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'PAYMENT', 
    'FEE', 'INTEREST_CREDIT', 'INTEREST_DEBIT', 
    'REFUND', 'REVERSAL', 'ADJUSTMENT'
);

-- Transaction Status Enum
CREATE TYPE transaction_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED', 'CANCELLED');

-- Transaction Channel Enum
CREATE TYPE transaction_channel AS ENUM ('ATM', 'BRANCH', 'ONLINE', 'MOBILE', 'POS', 'API', 'INTERNAL');

-- Transactions Table
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    
    -- Account Information
    from_account_id BIGINT,
    to_account_id BIGINT,
    
    -- Transaction Details
    transaction_type transaction_type NOT NULL,
    transaction_status transaction_status DEFAULT 'PENDING',
    transaction_channel transaction_channel NOT NULL,
    
    -- Amounts
    amount DECIMAL(19, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    fee DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Exchange Rate (for currency conversion)
    exchange_rate DECIMAL(10, 6) DEFAULT 1.0,
    original_amount DECIMAL(19, 2),
    original_currency VARCHAR(3),
    
    -- Balances
    from_account_balance_before DECIMAL(19, 2),
    from_account_balance_after DECIMAL(19, 2),
    to_account_balance_before DECIMAL(19, 2),
    to_account_balance_after DECIMAL(19, 2),
    
    -- Description
    description TEXT,
    reference_number VARCHAR(100),
    external_reference VARCHAR(100),
    
    -- Beneficiary (for transfers/payments)
    beneficiary_name VARCHAR(255),
    beneficiary_account VARCHAR(50),
    beneficiary_bank VARCHAR(255),
    
    -- Timestamps
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    failed_at TIMESTAMP,
    
    -- Processing
    processed_by VARCHAR(100),
    approved_by VARCHAR(100),
    
    -- Failure Handling
    failure_reason TEXT,
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    
    -- Reversal
    is_reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMP,
    reversal_transaction_id VARCHAR(100),
    reversal_reason TEXT,
    
    -- Location (for ATM/POS)
    location_name VARCHAR(255),
    location_address TEXT,
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    
    -- Device Information
    device_id VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Security
    requires_approval BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    fraud_score INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT different_accounts CHECK (from_account_id IS NULL OR to_account_id IS NULL OR from_account_id != to_account_id)
);

-- Transaction Batches (for bulk processing)
CREATE TABLE transaction_batches (
    id BIGSERIAL PRIMARY KEY,
    batch_id VARCHAR(100) UNIQUE NOT NULL,
    batch_type VARCHAR(50) NOT NULL,
    total_transactions INT DEFAULT 0,
    successful_transactions INT DEFAULT 0,
    failed_transactions INT DEFAULT 0,
    total_amount DECIMAL(19, 2) DEFAULT 0.00,
    batch_status VARCHAR(20) DEFAULT 'PENDING',
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Link transactions to batches
CREATE TABLE transaction_batch_items (
    id BIGSERIAL PRIMARY KEY,
    batch_id BIGINT NOT NULL REFERENCES transaction_batches(id) ON DELETE CASCADE,
    transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    item_status VARCHAR(20) DEFAULT 'PENDING',
    error_message TEXT,
    processed_at TIMESTAMP,
    
    UNIQUE(batch_id, transaction_id)
);

-- Standing Orders / Recurring Transactions
CREATE TABLE standing_orders (
    id BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(100) UNIQUE NOT NULL,
    from_account_id BIGINT NOT NULL,
    to_account_id BIGINT NOT NULL,
    
    -- Order Details
    amount DECIMAL(19, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    
    -- Schedule
    frequency VARCHAR(20) NOT NULL, -- DAILY, WEEKLY, MONTHLY, YEARLY
    start_date DATE NOT NULL,
    end_date DATE,
    next_execution_date DATE NOT NULL,
    last_execution_date DATE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    execution_count INT DEFAULT 0,
    failed_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    
    CONSTRAINT positive_so_amount CHECK (amount > 0),
    CONSTRAINT different_so_accounts CHECK (from_account_id != to_account_id)
);

-- Transaction Approvals (for high-value transactions)
CREATE TABLE transaction_approvals (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    approval_level INT NOT NULL,
    required_approvals INT DEFAULT 1,
    current_approvals INT DEFAULT 0,
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Individual Approval Records
CREATE TABLE approval_records (
    id BIGSERIAL PRIMARY KEY,
    transaction_approval_id BIGINT NOT NULL REFERENCES transaction_approvals(id) ON DELETE CASCADE,
    approved_by VARCHAR(100) NOT NULL,
    approval_decision VARCHAR(20) NOT NULL, -- APPROVED, REJECTED
    comments TEXT,
    approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction Limits (Daily, Monthly)
CREATE TABLE transaction_limits (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL,
    limit_type VARCHAR(20) NOT NULL, -- DAILY, MONTHLY
    transaction_type transaction_type NOT NULL,
    limit_amount DECIMAL(19, 2) NOT NULL,
    used_amount DECIMAL(19, 2) DEFAULT 0.00,
    transaction_count INT DEFAULT 0,
    reset_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(account_id, limit_type, transaction_type),
    CONSTRAINT positive_limit CHECK (limit_amount > 0)
);

-- Transaction Disputes
CREATE TABLE transaction_disputes (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    dispute_id VARCHAR(100) UNIQUE NOT NULL,
    
    -- Dispute Details
    dispute_reason VARCHAR(100) NOT NULL,
    dispute_description TEXT NOT NULL,
    dispute_amount DECIMAL(19, 2),
    
    -- Status
    dispute_status VARCHAR(20) DEFAULT 'SUBMITTED',
    resolution VARCHAR(20),
    resolution_notes TEXT,
    
    -- Dates
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    
    -- Processing
    submitted_by VARCHAR(100),
    assigned_to VARCHAR(100),
    resolved_by VARCHAR(100),
    
    -- Refund
    refund_amount DECIMAL(19, 2),
    refund_transaction_id BIGINT REFERENCES transactions(id)
);

-- Transaction Notifications
CREATE TABLE transaction_notifications (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    notification_channel VARCHAR(20) NOT NULL, -- EMAIL, SMS, PUSH
    notification_status VARCHAR(20) DEFAULT 'PENDING',
    sent_at TIMESTAMP,
    delivery_status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_transactions_transaction_id ON transactions(transaction_id);
CREATE INDEX idx_transactions_from_account ON transactions(from_account_id);
CREATE INDEX idx_transactions_to_account ON transactions(to_account_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_status ON transactions(transaction_status);
CREATE INDEX idx_transactions_date ON transactions(initiated_at);
CREATE INDEX idx_transactions_channel ON transactions(transaction_channel);
CREATE INDEX idx_standing_orders_from_account ON standing_orders(from_account_id);
CREATE INDEX idx_standing_orders_next_execution ON standing_orders(next_execution_date);
CREATE INDEX idx_standing_orders_active ON standing_orders(is_active);
CREATE INDEX idx_transaction_limits_account ON transaction_limits(account_id);
CREATE INDEX idx_transaction_disputes_transaction ON transaction_disputes(transaction_id);
CREATE INDEX idx_transaction_disputes_status ON transaction_disputes(dispute_status);

-- Update triggers
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_standing_orders_updated_at BEFORE UPDATE ON standing_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO transaction_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO transaction_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Transaction database schema created successfully!'
