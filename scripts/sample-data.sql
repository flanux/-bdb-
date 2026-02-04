-- ============================================
-- Sample Data for Testing
-- Run after all schemas are created
-- ============================================

-- CUSTOMERS
\c customer_db;

INSERT INTO customers (customer_number, customer_type, first_name, last_name, date_of_birth, email, phone_number, address_line1, city, state, postal_code, country, customer_status, kyc_status)
VALUES 
('CUST001', 'INDIVIDUAL', 'John', 'Doe', '1990-01-15', 'john.doe@example.com', '+1234567890', '123 Main St', 'New York', 'NY', '10001', 'USA', 'ACTIVE', 'VERIFIED'),
('CUST002', 'INDIVIDUAL', 'Jane', 'Smith', '1985-05-20', 'jane.smith@example.com', '+1234567891', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', 'ACTIVE', 'VERIFIED'),
('CUST003', 'INDIVIDUAL', 'Robert', 'Johnson', '1992-08-10', 'robert.j@example.com', '+1234567892', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', 'ACTIVE', 'PENDING');

-- ACCOUNTS
\c account_db;

INSERT INTO accounts (account_number, customer_id, account_type, account_status, balance, currency, interest_rate, branch_code, created_by)
VALUES 
('ACC1001234567', 1, 'SAVINGS', 'ACTIVE', 15000.00, 'USD', 2.5, 'BR001', 'system'),
('ACC1002345678', 1, 'CHECKING', 'ACTIVE', 5000.00, 'USD', 0.0, 'BR001', 'system'),
('ACC1003456789', 2, 'SAVINGS', 'ACTIVE', 25000.00, 'USD', 2.5, 'BR002', 'system'),
('ACC1004567890', 2, 'CHECKING', 'ACTIVE', 8000.00, 'USD', 0.0, 'BR002', 'system'),
('ACC1005678901', 3, 'SAVINGS', 'ACTIVE', 10000.00, 'USD', 2.5, 'BR001', 'system');

-- CARDS
\c card_db;

INSERT INTO cards (card_number, card_holder_name, customer_id, account_id, card_type, card_network, card_status, last_four_digits, issue_date, expiry_date, credit_limit, available_credit, created_by)
VALUES 
('4532123456789012', 'JOHN DOE', 1, 1, 'DEBIT', 'VISA', 'ACTIVE', '9012', '2024-01-01', '2027-01-01', 0, 0, 'system'),
('5412345678901234', 'JOHN DOE', 1, 1, 'CREDIT', 'MASTERCARD', 'ACTIVE', '1234', '2024-01-01', '2027-01-01', 10000.00, 10000.00, 'system'),
('4532234567890123', 'JANE SMITH', 2, 3, 'DEBIT', 'VISA', 'ACTIVE', '0123', '2024-01-15', '2027-01-15', 0, 0, 'system'),
('378282246310005', 'JANE SMITH', 2, 3, 'CREDIT', 'AMEX', 'ACTIVE', '0005', '2024-01-15', '2027-01-15', 15000.00, 15000.00, 'system');

-- LOANS
\c loan_db;

INSERT INTO loans (loan_number, customer_id, account_id, loan_type, loan_status, principal_amount, interest_rate, loan_term_months, monthly_payment, outstanding_balance, application_date, approval_date, disbursement_date, maturity_date, approved_by)
VALUES 
('LOAN001', 1, 1, 'PERSONAL', 'ACTIVE', 20000.00, 8.5, 60, 410.00, 18500.00, '2024-01-01', '2024-01-05', '2024-01-10', '2029-01-10', 'loan_officer_1'),
('LOAN002', 2, 3, 'AUTO', 'ACTIVE', 35000.00, 6.5, 72, 565.00, 32000.00, '2023-12-15', '2023-12-20', '2023-12-25', '2029-12-25', 'loan_officer_2'),
('LOAN003', 3, 5, 'HOME', 'PENDING', 250000.00, 5.5, 360, 1420.00, 250000.00, '2024-02-01', NULL, NULL, NULL, NULL);

-- TRANSACTIONS
\c transaction_db;

INSERT INTO transactions (transaction_id, from_account_id, to_account_id, transaction_type, transaction_status, transaction_channel, amount, currency, description, initiated_at, completed_at, processed_by)
VALUES 
('TXN001', 1, NULL, 'DEPOSIT', 'COMPLETED', 'BRANCH', 5000.00, 'USD', 'Cash deposit', '2024-02-01 10:00:00', '2024-02-01 10:00:05', 'teller_1'),
('TXN002', 2, 4, 'TRANSFER', 'COMPLETED', 'ONLINE', 500.00, 'USD', 'Transfer to Jane', '2024-02-01 14:30:00', '2024-02-01 14:30:10', 'system'),
('TXN003', 3, NULL, 'WITHDRAWAL', 'COMPLETED', 'ATM', 200.00, 'USD', 'ATM withdrawal', '2024-02-02 09:15:00', '2024-02-02 09:15:05', 'atm_001'),
('TXN004', NULL, 1, 'INTEREST_CREDIT', 'COMPLETED', 'INTERNAL', 31.25, 'USD', 'Monthly interest', '2024-02-01 00:00:00', '2024-02-01 00:00:01', 'system'),
('TXN005', 4, NULL, 'PAYMENT', 'COMPLETED', 'ONLINE', 100.00, 'USD', 'Utility payment', '2024-02-02 16:45:00', '2024-02-02 16:45:08', 'system');

-- LEDGER
\c ledger_db;

-- Create GL Accounts first
INSERT INTO gl_accounts (account_code, account_name, account_type, balance)
VALUES 
('1000', 'Cash', 'ASSET', 50000.00),
('1100', 'Customer Deposits', 'ASSET', 100000.00),
('2000', 'Customer Accounts Payable', 'LIABILITY', 100000.00),
('3000', 'Shareholder Equity', 'EQUITY', 50000.00),
('4000', 'Interest Income', 'REVENUE', 0.00),
('5000', 'Operating Expenses', 'EXPENSE', 0.00);

-- AUTH
\c auth_db;

-- Password is "password123" hashed with BCrypt
INSERT INTO users (username, email, password_hash, user_role, user_status, customer_id, is_email_verified)
VALUES 
('john.doe', 'john.doe@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER', 'ACTIVE', 1, true),
('jane.smith', 'jane.smith@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER', 'ACTIVE', 2, true),
('robert.j', 'robert.j@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER', 'ACTIVE', 3, true),
('admin', 'admin@flanux.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'ADMIN', 'ACTIVE', NULL, true);

-- NOTIFICATIONS
\c notification_db;

INSERT INTO notification_templates (template_id, template_name, notification_type, subject_template, body_template)
VALUES 
('WELCOME_EMAIL', 'Welcome Email', 'EMAIL', 'Welcome to Flanux Bank!', 'Dear {{customer_name}}, Welcome to Flanux Bank. Your account has been created successfully.'),
('TRANSACTION_ALERT', 'Transaction Alert', 'SMS', NULL, 'Transaction of {{amount}} {{currency}} on account {{account_number}}'),
('LOAN_APPROVED', 'Loan Approval', 'EMAIL', 'Your Loan Has Been Approved', 'Dear {{customer_name}}, Congratulations! Your loan application for {{amount}} has been approved.');

INSERT INTO notification_preferences (customer_id, email_enabled, sms_enabled, push_enabled, transaction_alerts, account_updates, security_alerts)
VALUES 
(1, true, true, true, true, true, true),
(2, true, true, false, true, true, true),
(3, true, false, false, true, true, true);

\echo '✅ Sample data inserted successfully!'
\echo '📊 Summary:'
\echo '  - 3 Customers'
\echo '  - 5 Accounts'
\echo '  - 4 Cards'
\echo '  - 3 Loans'
\echo '  - 5 Transactions'
\echo '  - 6 GL Accounts'
\echo '  - 4 Users (password: password123)'
\echo '  - 3 Notification Templates'
