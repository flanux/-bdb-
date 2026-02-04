-- ============================================
-- Loan Service Database Schema
-- ============================================

\c loan_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Loan Type Enum
CREATE TYPE loan_type AS ENUM ('PERSONAL', 'HOME', 'AUTO', 'EDUCATION', 'BUSINESS', 'MORTGAGE');

-- Loan Status Enum
CREATE TYPE loan_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'ACTIVE', 'PAID_OFF', 'DEFAULTED', 'CLOSED');

-- Payment Status Enum
CREATE TYPE payment_status AS ENUM ('PENDING', 'PAID', 'OVERDUE', 'PARTIAL', 'FAILED');

-- Loans Table
CREATE TABLE loans (
    id BIGSERIAL PRIMARY KEY,
    loan_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    account_id BIGINT,
    
    -- Loan Details
    loan_type loan_type NOT NULL,
    loan_status loan_status DEFAULT 'PENDING',
    principal_amount DECIMAL(19, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) NOT NULL,
    loan_term_months INT NOT NULL,
    monthly_payment DECIMAL(19, 2) NOT NULL,
    
    -- Balances
    outstanding_balance DECIMAL(19, 2) NOT NULL,
    principal_paid DECIMAL(19, 2) DEFAULT 0.00,
    interest_paid DECIMAL(19, 2) DEFAULT 0.00,
    fees_paid DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Dates
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    approval_date DATE,
    disbursement_date DATE,
    first_payment_date DATE,
    maturity_date DATE,
    last_payment_date DATE,
    
    -- Purpose and Security
    loan_purpose TEXT,
    collateral_description TEXT,
    collateral_value DECIMAL(19, 2),
    
    -- Credit Score at Application
    credit_score_at_application INT,
    
    -- Processing
    approved_by VARCHAR(100),
    rejected_by VARCHAR(100),
    rejection_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    CONSTRAINT positive_principal CHECK (principal_amount > 0),
    CONSTRAINT positive_interest CHECK (interest_rate >= 0),
    CONSTRAINT positive_term CHECK (loan_term_months > 0),
    CONSTRAINT valid_balance CHECK (outstanding_balance >= 0)
);

-- Loan Payments
CREATE TABLE loan_payments (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    payment_number INT NOT NULL,
    
    -- Payment Details
    due_date DATE NOT NULL,
    payment_date DATE,
    payment_amount DECIMAL(19, 2) NOT NULL,
    principal_amount DECIMAL(19, 2) DEFAULT 0.00,
    interest_amount DECIMAL(19, 2) DEFAULT 0.00,
    fees_amount DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Status
    payment_status payment_status DEFAULT 'PENDING',
    
    -- Late Payment
    late_fee DECIMAL(19, 2) DEFAULT 0.00,
    days_overdue INT DEFAULT 0,
    
    -- Transaction Reference
    transaction_id VARCHAR(100),
    payment_method VARCHAR(50),
    
    -- Balances After Payment
    balance_after_payment DECIMAL(19, 2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(loan_id, payment_number),
    CONSTRAINT positive_payment CHECK (payment_amount >= 0)
);

-- Loan Applications (Before approval)
CREATE TABLE loan_applications (
    id BIGSERIAL PRIMARY KEY,
    application_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    
    -- Application Details
    loan_type loan_type NOT NULL,
    requested_amount DECIMAL(19, 2) NOT NULL,
    loan_term_months INT NOT NULL,
    loan_purpose TEXT NOT NULL,
    
    -- Applicant Information
    employment_status VARCHAR(50),
    employer_name VARCHAR(255),
    monthly_income DECIMAL(19, 2),
    existing_debts DECIMAL(19, 2) DEFAULT 0.00,
    
    -- Collateral
    has_collateral BOOLEAN DEFAULT FALSE,
    collateral_type VARCHAR(100),
    collateral_value DECIMAL(19, 2),
    
    -- Credit Check
    credit_score INT,
    credit_check_date DATE,
    debt_to_income_ratio DECIMAL(5, 2),
    
    -- Application Status
    application_status VARCHAR(20) DEFAULT 'SUBMITTED',
    risk_assessment VARCHAR(20),
    approved_amount DECIMAL(19, 2),
    approved_rate DECIMAL(5, 2),
    
    -- Processing
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by VARCHAR(100),
    decision_date DATE,
    decision_notes TEXT,
    
    -- If approved, link to loan
    loan_id BIGINT REFERENCES loans(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_requested CHECK (requested_amount > 0)
);

-- Loan Collateral
CREATE TABLE loan_collateral (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    collateral_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    estimated_value DECIMAL(19, 2) NOT NULL,
    valuation_date DATE,
    valuation_by VARCHAR(100),
    insurance_policy_number VARCHAR(100),
    insurance_expiry DATE,
    location TEXT,
    registration_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_value CHECK (estimated_value > 0)
);

-- Loan Payment Schedule
CREATE TABLE loan_payment_schedule (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    payment_number INT NOT NULL,
    payment_date DATE NOT NULL,
    principal_amount DECIMAL(19, 2) NOT NULL,
    interest_amount DECIMAL(19, 2) NOT NULL,
    total_payment DECIMAL(19, 2) NOT NULL,
    remaining_balance DECIMAL(19, 2) NOT NULL,
    
    UNIQUE(loan_id, payment_number)
);

-- Loan Restructuring History
CREATE TABLE loan_restructuring (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    restructure_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reason TEXT NOT NULL,
    
    -- Old Terms
    old_interest_rate DECIMAL(5, 2),
    old_term_months INT,
    old_monthly_payment DECIMAL(19, 2),
    
    -- New Terms
    new_interest_rate DECIMAL(5, 2),
    new_term_months INT,
    new_monthly_payment DECIMAL(19, 2),
    
    approved_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_loans_loan_number ON loans(loan_number);
CREATE INDEX idx_loans_customer_id ON loans(customer_id);
CREATE INDEX idx_loans_status ON loans(loan_status);
CREATE INDEX idx_loans_type ON loans(loan_type);
CREATE INDEX idx_loan_payments_loan_id ON loan_payments(loan_id);
CREATE INDEX idx_loan_payments_status ON loan_payments(payment_status);
CREATE INDEX idx_loan_payments_due_date ON loan_payments(due_date);
CREATE INDEX idx_loan_applications_customer_id ON loan_applications(customer_id);
CREATE INDEX idx_loan_applications_status ON loan_applications(application_status);
CREATE INDEX idx_loan_collateral_loan_id ON loan_collateral(loan_id);

-- Update triggers
CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_payments_updated_at BEFORE UPDATE ON loan_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_applications_updated_at BEFORE UPDATE ON loan_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO loan_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO loan_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Loan database schema created successfully!'
