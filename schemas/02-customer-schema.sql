-- ============================================
-- Customer Service Database Schema
-- ============================================

\c customer_db;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Customer Type Enum
CREATE TYPE customer_type AS ENUM ('INDIVIDUAL', 'CORPORATE', 'JOINT');

-- Customer Status Enum
CREATE TYPE customer_status AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED', 'PENDING_VERIFICATION', 'DECEASED');

-- KYC Status Enum
CREATE TYPE kyc_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'EXPIRED', 'UNDER_REVIEW');

-- Customers Table
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    customer_type customer_type NOT NULL,
    customer_status customer_status DEFAULT 'PENDING_VERIFICATION',
    kyc_status kyc_status DEFAULT 'PENDING',
    
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20),
    nationality VARCHAR(50),
    
    -- Contact Information
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    
    -- Address Information
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    
    -- Identification
    ssn_last4 VARCHAR(4),
    tax_id VARCHAR(50),
    id_type VARCHAR(50),
    id_number VARCHAR(100),
    id_expiry_date DATE,
    
    -- Employment
    occupation VARCHAR(100),
    employer_name VARCHAR(255),
    annual_income DECIMAL(19, 2),
    
    -- Preferences
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL',
    marketing_consent BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    last_login TIMESTAMP,
    kyc_verified_at TIMESTAMP,
    kyc_verified_by VARCHAR(100),
    
    CONSTRAINT valid_dob CHECK (date_of_birth < CURRENT_DATE),
    CONSTRAINT valid_age CHECK (EXTRACT(YEAR FROM AGE(date_of_birth)) >= 18)
);

-- Customer Documents (KYC)
CREATE TABLE customer_documents (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    verification_status kyc_status DEFAULT 'PENDING',
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP,
    verified_by VARCHAR(100),
    expiry_date DATE,
    notes TEXT,
    
    UNIQUE(customer_id, document_type, document_number)
);

-- Customer Addresses (Multiple addresses)
CREATE TABLE customer_addresses (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_type VARCHAR(20) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) DEFAULT 'USA',
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer Relationships (Joint accounts, dependents, etc.)
CREATE TABLE customer_relationships (
    id BIGSERIAL PRIMARY KEY,
    primary_customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    related_customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,
    relationship_status VARCHAR(20) DEFAULT 'ACTIVE',
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT different_customers CHECK (primary_customer_id != related_customer_id),
    UNIQUE(primary_customer_id, related_customer_id, relationship_type)
);

-- Customer Notes
CREATE TABLE customer_notes (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    note_type VARCHAR(50) NOT NULL,
    note_text TEXT NOT NULL,
    is_important BOOLEAN DEFAULT FALSE,
    is_internal BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL
);

-- Customer Risk Profile
CREATE TABLE customer_risk_profiles (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL UNIQUE REFERENCES customers(id) ON DELETE CASCADE,
    risk_score INT DEFAULT 0,
    risk_level VARCHAR(20) DEFAULT 'LOW',
    risk_factors JSONB,
    last_assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assessed_by VARCHAR(100),
    next_review_date DATE,
    notes TEXT,
    
    CONSTRAINT valid_risk_score CHECK (risk_score >= 0 AND risk_score <= 100)
);

-- Indexes
CREATE INDEX idx_customers_customer_number ON customers(customer_number);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone_number);
CREATE INDEX idx_customers_status ON customers(customer_status);
CREATE INDEX idx_customers_kyc_status ON customers(kyc_status);
CREATE INDEX idx_customers_type ON customers(customer_type);
CREATE INDEX idx_customer_documents_customer_id ON customer_documents(customer_id);
CREATE INDEX idx_customer_documents_status ON customer_documents(verification_status);
CREATE INDEX idx_customer_addresses_customer_id ON customer_addresses(customer_id);
CREATE INDEX idx_customer_relationships_primary ON customer_relationships(primary_customer_id);
CREATE INDEX idx_customer_relationships_related ON customer_relationships(related_customer_id);
CREATE INDEX idx_customer_notes_customer_id ON customer_notes(customer_id);

-- Update timestamp trigger
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customer_addresses_updated_at BEFORE UPDATE ON customer_addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO customer_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO customer_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

\echo 'Customer database schema created successfully!'
