# Database Migration Guide

## Using Flyway for Version Control

Flyway helps manage database schema changes over time.

### Directory Structure

```
-ms-account-service/
└── src/main/resources/
    └── db/migration/
        ├── V1__create_accounts_table.sql
        ├── V2__add_beneficiaries_table.sql
        └── V3__add_account_holds.sql
```

### Naming Convention

```
V{version}__{description}.sql

Examples:
V1__initial_schema.sql
V2__add_customer_notes.sql
V3__add_risk_profile.sql
V3.1__add_index_on_email.sql (for patches)
```

### Example Migration File

**V1__create_accounts_table.sql**

```sql
CREATE TYPE account_type AS ENUM ('SAVINGS', 'CHECKING', 'FIXED_DEPOSIT', 'CURRENT', 'SALARY');
CREATE TYPE account_status AS ENUM ('ACTIVE', 'INACTIVE', 'FROZEN', 'CLOSED', 'SUSPENDED');

CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    account_type account_type NOT NULL,
    account_status account_status DEFAULT 'ACTIVE',
    balance DECIMAL(19, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
```

### Flyway Configuration

**application.yml**

```yaml
spring:
  flyway:
    enabled: true
    baseline-on-migrate: true
    baseline-version: 0
    locations: classpath:db/migration
    validate-on-migrate: true
    out-of-order: false
```

### Running Migrations

```bash
# Migrations run automatically on application startup
mvn spring-boot:run

# Or manually with Flyway Maven plugin
mvn flyway:migrate
mvn flyway:info
mvn flyway:validate
```

### Migration Commands

```bash
# Check migration status
mvn flyway:info

# Migrate to latest version
mvn flyway:migrate

# Validate migrations
mvn flyway:validate

# Clean database (⚠️ DANGER: Deletes everything!)
mvn flyway:clean

# Repair metadata table
mvn flyway:repair
```

### Best Practices

1. **Never modify existing migrations** - Create new ones instead
2. **Test migrations** - Always test on dev/staging first
3. **Keep migrations small** - One logical change per migration
4. **Include rollback plan** - Document how to undo changes
5. **Version control** - Commit migrations with code changes
6. **Data migrations** - Use separate files for data changes

### Rollback Strategy

Flyway doesn't support automatic rollback. You need to create undo migrations:

```sql
-- V4__add_email_column.sql
ALTER TABLE customers ADD COLUMN email VARCHAR(255);

-- V5__rollback_email_column.sql (if needed)
ALTER TABLE customers DROP COLUMN email;
```

### Data Migrations

**V10__seed_gl_accounts.sql**

```sql
INSERT INTO gl_accounts (account_code, account_name, account_type)
VALUES 
    ('1000', 'Cash', 'ASSET'),
    ('2000', 'Accounts Payable', 'LIABILITY'),
    ('3000', 'Equity', 'EQUITY');
```

### Migration History

Flyway tracks migrations in `flyway_schema_history` table:

```sql
SELECT * FROM flyway_schema_history;
```

Output:
```
installed_rank | version | description           | type | script                        | checksum    | installed_on        | execution_time | success
1              | 1       | create accounts table | SQL  | V1__create_accounts_table.sql | -1234567890 | 2024-02-04 10:00:00 | 45             | t
2              | 2       | add beneficiaries     | SQL  | V2__add_beneficiaries.sql     | 987654321   | 2024-02-04 10:00:01 | 32             | t
```

### Troubleshooting

**Issue: Checksum mismatch**
```bash
# Repair the metadata
mvn flyway:repair
```

**Issue: Out-of-order migration**
```yaml
# Allow out-of-order (not recommended)
spring:
  flyway:
    out-of-order: true
```

**Issue: Failed migration**
```bash
# Check what failed
mvn flyway:info

# Fix the migration file
# Repair metadata
mvn flyway:repair

# Try again
mvn flyway:migrate
```

## Without Flyway (Manual Approach)

If you prefer manual control:

1. Set `spring.jpa.hibernate.ddl-auto=none`
2. Run SQL scripts manually
3. Track versions in a separate table

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: none  # Don't auto-generate schema
```

Then run schemas manually:
```bash
psql -U account_user -d account_db -f schemas/01-account-schema.sql
```
