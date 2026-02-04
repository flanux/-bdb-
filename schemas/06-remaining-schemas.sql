-- ============================================
-- Ledger Service Database Schema
-- ============================================

\c ledger_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE entry_type AS ENUM ('DEBIT', 'CREDIT');
CREATE TYPE ledger_status AS ENUM ('DRAFT', 'POSTED', 'REVERSED', 'CLOSED');

-- General Ledger Accounts
CREATE TABLE gl_accounts (
    id BIGSERIAL PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    parent_account_id BIGINT REFERENCES gl_accounts(id),
    balance DECIMAL(19, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ledger Entries (Double-entry bookkeeping)
CREATE TABLE ledger_entries (
    id BIGSERIAL PRIMARY KEY,
    entry_id VARCHAR(100) UNIQUE NOT NULL,
    transaction_id VARCHAR(100) NOT NULL,
    entry_date DATE NOT NULL,
    posting_date DATE,
    
    -- Entry Details
    gl_account_id BIGINT NOT NULL REFERENCES gl_accounts(id),
    entry_type entry_type NOT NULL,
    amount DECIMAL(19, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Reference
    reference_type VARCHAR(50),
    reference_id BIGINT,
    description TEXT NOT NULL,
    
    -- Status
    entry_status ledger_status DEFAULT 'DRAFT',
    
    -- Processing
    posted_by VARCHAR(100),
    approved_by VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_ledger_amount CHECK (amount > 0)
);

-- Journal Entries (Groups related ledger entries)
CREATE TABLE journal_entries (
    id BIGSERIAL PRIMARY KEY,
    journal_id VARCHAR(100) UNIQUE NOT NULL,
    journal_date DATE NOT NULL,
    posting_date DATE,
    description TEXT NOT NULL,
    total_debit DECIMAL(19, 2) DEFAULT 0.00,
    total_credit DECIMAL(19, 2) DEFAULT 0.00,
    journal_status ledger_status DEFAULT 'DRAFT',
    created_by VARCHAR(100),
    posted_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT balanced_journal CHECK (total_debit = total_credit OR journal_status = 'DRAFT')
);

-- Link journal to ledger entries
CREATE TABLE journal_ledger_entries (
    journal_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    ledger_entry_id BIGINT NOT NULL REFERENCES ledger_entries(id) ON DELETE CASCADE,
    PRIMARY KEY (journal_id, ledger_entry_id)
);

-- Account Balances Snapshot (for reporting)
CREATE TABLE account_balance_snapshots (
    id BIGSERIAL PRIMARY KEY,
    gl_account_id BIGINT NOT NULL REFERENCES gl_accounts(id),
    snapshot_date DATE NOT NULL,
    opening_balance DECIMAL(19, 2) NOT NULL,
    closing_balance DECIMAL(19, 2) NOT NULL,
    total_debits DECIMAL(19, 2) DEFAULT 0.00,
    total_credits DECIMAL(19, 2) DEFAULT 0.00,
    
    UNIQUE(gl_account_id, snapshot_date)
);

CREATE INDEX idx_ledger_entries_transaction ON ledger_entries(transaction_id);
CREATE INDEX idx_ledger_entries_gl_account ON ledger_entries(gl_account_id);
CREATE INDEX idx_ledger_entries_date ON ledger_entries(entry_date);
CREATE INDEX idx_journal_entries_date ON journal_entries(journal_date);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ledger_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ledger_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Ledger database schema created successfully!'

-- ============================================
-- Notification Service Database Schema
-- ============================================

\c notification_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE notification_type AS ENUM ('EMAIL', 'SMS', 'PUSH', 'IN_APP');
CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'READ');
CREATE TYPE notification_priority AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');

-- Notifications
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    notification_id VARCHAR(100) UNIQUE NOT NULL,
    
    -- Recipient
    recipient_id BIGINT NOT NULL,
    recipient_type VARCHAR(50) NOT NULL, -- CUSTOMER, EMPLOYEE, ADMIN
    
    -- Notification Details
    notification_type notification_type NOT NULL,
    notification_priority notification_priority DEFAULT 'NORMAL',
    
    -- Content
    subject VARCHAR(500),
    message TEXT NOT NULL,
    template_id VARCHAR(100),
    template_data JSONB,
    
    -- Delivery
    delivery_address VARCHAR(255) NOT NULL, -- email/phone/device_token
    notification_status notification_status DEFAULT 'PENDING',
    
    -- Attempts
    send_attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    
    -- Timestamps
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    failed_at TIMESTAMP,
    
    -- Error Handling
    error_message TEXT,
    
    -- Reference
    reference_type VARCHAR(50),
    reference_id BIGINT,
    
    -- Metadata
    metadata JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification Templates
CREATE TABLE notification_templates (
    id BIGSERIAL PRIMARY KEY,
    template_id VARCHAR(100) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    notification_type notification_type NOT NULL,
    subject_template VARCHAR(500),
    body_template TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification Preferences (user settings)
CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL UNIQUE,
    
    -- Channel Preferences
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    
    -- Category Preferences
    transaction_alerts BOOLEAN DEFAULT TRUE,
    account_updates BOOLEAN DEFAULT TRUE,
    promotional BOOLEAN DEFAULT FALSE,
    security_alerts BOOLEAN DEFAULT TRUE,
    
    -- Quiet Hours
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification Batches
CREATE TABLE notification_batches (
    id BIGSERIAL PRIMARY KEY,
    batch_id VARCHAR(100) UNIQUE NOT NULL,
    batch_type VARCHAR(50) NOT NULL,
    total_notifications INT DEFAULT 0,
    sent_notifications INT DEFAULT 0,
    failed_notifications INT DEFAULT 0,
    batch_status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_status ON notifications(notification_status);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_at);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO notification_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO notification_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Notification database schema created successfully!'

-- ============================================
-- Reporting Service Database Schema
-- ============================================

\c reporting_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE report_type AS ENUM ('FINANCIAL', 'COMPLIANCE', 'OPERATIONAL', 'ANALYTICAL', 'REGULATORY');
CREATE TYPE report_status AS ENUM ('SCHEDULED', 'GENERATING', 'COMPLETED', 'FAILED');
CREATE TYPE report_format AS ENUM ('PDF', 'EXCEL', 'CSV', 'JSON');

-- Reports
CREATE TABLE reports (
    id BIGSERIAL PRIMARY KEY,
    report_id VARCHAR(100) UNIQUE NOT NULL,
    report_name VARCHAR(255) NOT NULL,
    report_type report_type NOT NULL,
    report_format report_format DEFAULT 'PDF',
    
    -- Parameters
    parameters JSONB,
    date_from DATE,
    date_to DATE,
    
    -- Generation
    report_status report_status DEFAULT 'SCHEDULED',
    file_path VARCHAR(500),
    file_size BIGINT,
    
    -- Scheduling
    is_scheduled BOOLEAN DEFAULT FALSE,
    schedule_frequency VARCHAR(20), -- DAILY, WEEKLY, MONTHLY
    next_run_date TIMESTAMP,
    
    -- Timestamps
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Processing
    generated_by VARCHAR(100),
    error_message TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Report Templates
CREATE TABLE report_templates (
    id BIGSERIAL PRIMARY KEY,
    template_id VARCHAR(100) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    report_type report_type NOT NULL,
    query_template TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Report Subscriptions
CREATE TABLE report_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    report_template_id BIGINT NOT NULL REFERENCES report_templates(id),
    subscriber_id BIGINT NOT NULL,
    subscriber_email VARCHAR(255) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Regulatory Reports (Compliance)
CREATE TABLE regulatory_reports (
    id BIGSERIAL PRIMARY KEY,
    report_id VARCHAR(100) UNIQUE NOT NULL,
    regulation_type VARCHAR(100) NOT NULL,
    reporting_period VARCHAR(50) NOT NULL,
    submission_deadline DATE NOT NULL,
    report_status report_status DEFAULT 'SCHEDULED',
    file_path VARCHAR(500),
    submitted_at TIMESTAMP,
    submitted_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reports_type ON reports(report_type);
CREATE INDEX idx_reports_status ON reports(report_status);
CREATE INDEX idx_reports_date_range ON reports(date_from, date_to);
CREATE INDEX idx_regulatory_reports_deadline ON regulatory_reports(submission_deadline);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO reporting_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO reporting_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Reporting database schema created successfully!'

-- ============================================
-- Auth Service Database Schema
-- ============================================

\c auth_db;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('CUSTOMER', 'EMPLOYEE', 'ADMIN', 'SUPER_ADMIN', 'AUDITOR');
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'LOCKED', 'SUSPENDED');

-- Users
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- User Details
    user_role user_role DEFAULT 'CUSTOMER',
    user_status user_status DEFAULT 'ACTIVE',
    
    -- Customer/Employee Link
    customer_id BIGINT,
    employee_id BIGINT,
    
    -- Security
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    
    -- Login Tracking
    last_login TIMESTAMP,
    last_login_ip VARCHAR(45),
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP,
    
    -- Password Management
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    password_expires_at TIMESTAMP,
    must_change_password BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Refresh Tokens
CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

-- Login History
CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_status VARCHAR(20) NOT NULL,
    failure_reason TEXT,
    location VARCHAR(255)
);

-- Permissions
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    permission_name VARCHAR(100) UNIQUE NOT NULL,
    permission_description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL
);

-- Role Permissions
CREATE TABLE role_permissions (
    role user_role NOT NULL,
    permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role, permission_id)
);

-- Password Reset Tokens
CREATE TABLE password_reset_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Email Verification Tokens
CREATE TABLE email_verification_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(user_status);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_login_history_user ON login_history(user_id);
CREATE INDEX idx_login_history_time ON login_history(login_time);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO auth_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO auth_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Auth database schema created successfully!'
