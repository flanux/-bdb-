-- ============================================
-- Card Service Database Schema
-- ============================================

\c card_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Card Type Enum
CREATE TYPE card_type AS ENUM ('DEBIT', 'CREDIT', 'PREPAID', 'VIRTUAL');

-- Card Status Enum
CREATE TYPE card_status AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED', 'EXPIRED', 'LOST', 'STOLEN', 'DAMAGED');

-- Card Network Enum
CREATE TYPE card_network AS ENUM ('VISA', 'MASTERCARD', 'AMEX', 'DISCOVER', 'RUPAY');

-- Cards Table
CREATE TABLE cards (
    id BIGSERIAL PRIMARY KEY,
    card_number VARCHAR(19) UNIQUE NOT NULL, -- Encrypted in production
    card_holder_name VARCHAR(255) NOT NULL,
    customer_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    
    -- Card Details
    card_type card_type NOT NULL,
    card_network card_network NOT NULL,
    card_status card_status DEFAULT 'INACTIVE',
    
    -- Card Numbers
    last_four_digits VARCHAR(4) NOT NULL,
    cvv VARCHAR(4), -- Encrypted in production
    pin_hash VARCHAR(255),
    
    -- Dates
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE NOT NULL,
    activation_date DATE,
    last_used_date TIMESTAMP,
    
    -- Limits (for credit cards)
    credit_limit DECIMAL(19, 2) DEFAULT 0.00,
    available_credit DECIMAL(19, 2) DEFAULT 0.00,
    current_balance DECIMAL(19, 2) DEFAULT 0.00,
    cash_advance_limit DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Daily Limits (security)
    daily_transaction_limit DECIMAL(19, 2) DEFAULT 5000.00,
    daily_atm_limit DECIMAL(19, 2) DEFAULT 1000.00,
    daily_online_limit DECIMAL(19, 2) DEFAULT 3000.00,
    
    -- Usage Counters (reset daily)
    daily_transaction_count INT DEFAULT 0,
    daily_transaction_amount DECIMAL(19, 2) DEFAULT 0.00,
    last_counter_reset DATE DEFAULT CURRENT_DATE,
    
    -- Features
    is_contactless_enabled BOOLEAN DEFAULT TRUE,
    is_international_enabled BOOLEAN DEFAULT FALSE,
    is_online_enabled BOOLEAN DEFAULT TRUE,
    is_atm_enabled BOOLEAN DEFAULT TRUE,
    
    -- Replacement (if lost/stolen)
    is_replacement BOOLEAN DEFAULT FALSE,
    original_card_id BIGINT REFERENCES cards(id),
    replacement_reason VARCHAR(100),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    CONSTRAINT valid_expiry CHECK (expiry_date > issue_date),
    CONSTRAINT positive_credit_limit CHECK (credit_limit >= 0),
    CONSTRAINT valid_available_credit CHECK (available_credit <= credit_limit)
);

-- Card Transactions
CREATE TABLE card_transactions (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    
    -- Transaction Details
    transaction_type VARCHAR(50) NOT NULL,
    transaction_amount DECIMAL(19, 2) NOT NULL,
    transaction_currency VARCHAR(3) DEFAULT 'USD',
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Merchant Details
    merchant_name VARCHAR(255),
    merchant_category VARCHAR(100),
    merchant_city VARCHAR(100),
    merchant_country VARCHAR(50),
    
    -- Authorization
    authorization_code VARCHAR(50),
    is_authorized BOOLEAN DEFAULT FALSE,
    authorization_date TIMESTAMP,
    
    -- Status
    transaction_status VARCHAR(20) DEFAULT 'PENDING',
    settlement_date DATE,
    
    -- Reversal
    is_reversed BOOLEAN DEFAULT FALSE,
    reversal_date TIMESTAMP,
    reversal_reason TEXT,
    
    -- Fees
    transaction_fee DECIMAL(19, 2) DEFAULT 0.00,
    foreign_exchange_fee DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Balance After Transaction
    balance_after DECIMAL(19, 2),
    
    -- Fraud Detection
    fraud_score INT DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    fraud_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_amount CHECK (transaction_amount > 0)
);

-- Card Applications
CREATE TABLE card_applications (
    id BIGSERIAL PRIMARY KEY,
    application_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    
    -- Application Details
    card_type card_type NOT NULL,
    card_network card_network NOT NULL,
    requested_credit_limit DECIMAL(19, 2),
    
    -- Applicant Info
    annual_income DECIMAL(19, 2),
    credit_score INT,
    existing_cards_count INT DEFAULT 0,
    
    -- Application Status
    application_status VARCHAR(20) DEFAULT 'SUBMITTED',
    approved_credit_limit DECIMAL(19, 2),
    
    -- Processing
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by VARCHAR(100),
    decision_date DATE,
    decision_notes TEXT,
    
    -- If approved, link to card
    card_id BIGINT REFERENCES cards(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Card Rewards
CREATE TABLE card_rewards (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    reward_type VARCHAR(50) NOT NULL,
    points_earned INT DEFAULT 0,
    points_redeemed INT DEFAULT 0,
    points_balance INT DEFAULT 0,
    cashback_earned DECIMAL(19, 2) DEFAULT 0.00,
    cashback_redeemed DECIMAL(19, 2) DEFAULT 0.00,
    cashback_balance DECIMAL(19, 2) DEFAULT 0.00,
    tier_level VARCHAR(20) DEFAULT 'BASIC',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Card Reward Transactions
CREATE TABLE card_reward_transactions (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL, -- EARN, REDEEM, EXPIRE
    points INT DEFAULT 0,
    cashback_amount DECIMAL(19, 2) DEFAULT 0.00,
    description TEXT,
    reference_transaction_id BIGINT REFERENCES card_transactions(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Card Statements
CREATE TABLE card_statements (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    statement_date DATE NOT NULL,
    billing_cycle_start DATE NOT NULL,
    billing_cycle_end DATE NOT NULL,
    
    -- Balances
    previous_balance DECIMAL(19, 2) DEFAULT 0.00,
    current_balance DECIMAL(19, 2) DEFAULT 0.00,
    minimum_payment_due DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Totals
    total_purchases DECIMAL(19, 2) DEFAULT 0.00,
    total_payments DECIMAL(19, 2) DEFAULT 0.00,
    total_fees DECIMAL(19, 2) DEFAULT 0.00,
    total_interest DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Due Date
    payment_due_date DATE NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    paid_date DATE,
    
    -- File
    statement_file_path VARCHAR(500),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(card_id, statement_date)
);

-- Card Blocks/Restrictions
CREATE TABLE card_restrictions (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    restriction_type VARCHAR(50) NOT NULL,
    restriction_reason TEXT NOT NULL,
    restricted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    restricted_by VARCHAR(100),
    lifted_at TIMESTAMP,
    lifted_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

-- Indexes
CREATE INDEX idx_cards_card_number ON cards(card_number);
CREATE INDEX idx_cards_customer_id ON cards(customer_id);
CREATE INDEX idx_cards_account_id ON cards(account_id);
CREATE INDEX idx_cards_status ON cards(card_status);
CREATE INDEX idx_cards_last_four ON cards(last_four_digits);
CREATE INDEX idx_card_transactions_card_id ON card_transactions(card_id);
CREATE INDEX idx_card_transactions_date ON card_transactions(transaction_date);
CREATE INDEX idx_card_transactions_status ON card_transactions(transaction_status);
CREATE INDEX idx_card_applications_customer_id ON card_applications(customer_id);
CREATE INDEX idx_card_statements_card_id ON card_statements(card_id);

-- Update triggers
CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_card_applications_updated_at BEFORE UPDATE ON card_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO card_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO card_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Card database schema created successfully!'
