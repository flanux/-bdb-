# Flanux Microservices - PostgreSQL Database Setup

Complete database infrastructure for all 8 microservices + auth service.

## 📊 Database Architecture

```
PostgreSQL Server (Port 5432)
├── account_db          → Account Service
├── customer_db         → Customer Service
├── loan_db             → Loan Service
├── card_db             → Card Service
├── transaction_db      → Transaction Service
├── ledger_db           → Ledger Service
├── notification_db     → Notification Service
├── reporting_db        → Reporting Service
└── auth_db             → Auth Service
```

## 🚀 Quick Start (5 Minutes)

### 1. Start PostgreSQL with Docker Compose

```bash
cd docker
docker-compose up -d
```

This will start:
- **PostgreSQL** on port `5432`
- **PgAdmin** on port `5050` (optional GUI)
- **Redis** on port `6379` (for caching)

### 2. Verify Setup

```bash
# Check if PostgreSQL is running
docker ps

# Check if databases were created
docker exec -it flanux-postgres psql -U flanux_admin -d postgres -c "\l"
```

You should see all 9 databases listed!

### 3. Access PgAdmin (Optional)

- URL: http://localhost:5050
- Email: `admin@flanux.com`
- Password: `admin123`

Add server:
- Host: `postgres`
- Port: `5432`
- Username: `flanux_admin`
- Password: `flanux_secure_password_2024`

## 📦 What's Included

### Database Schemas

Each database has production-ready schemas with:

1. **account_db**
   - `accounts` - Customer accounts
   - `account_beneficiaries` - Account beneficiaries
   - `account_statements` - Monthly statements
   - `account_holds` - Temporary holds on funds

2. **customer_db**
   - `customers` - Customer information
   - `customer_documents` - KYC documents
   - `customer_addresses` - Multiple addresses per customer
   - `customer_relationships` - Joint accounts, dependents
   - `customer_notes` - Internal notes
   - `customer_risk_profiles` - Risk assessment

3. **loan_db**
   - `loans` - Active loans
   - `loan_payments` - Payment history
   - `loan_applications` - Loan applications
   - `loan_collateral` - Collateral details
   - `loan_payment_schedule` - Amortization schedule
   - `loan_restructuring` - Restructuring history

4. **card_db**
   - `cards` - Credit/Debit cards
   - `card_transactions` - Card transactions
   - `card_applications` - Card applications
   - `card_rewards` - Rewards/cashback
   - `card_statements` - Monthly statements
   - `card_restrictions` - Blocks/restrictions

5. **transaction_db**
   - `transactions` - All transactions
   - `transaction_batches` - Bulk processing
   - `standing_orders` - Recurring payments
   - `transaction_approvals` - Multi-level approvals
   - `transaction_limits` - Daily/monthly limits
   - `transaction_disputes` - Dispute management

6. **ledger_db**
   - `gl_accounts` - General ledger accounts
   - `ledger_entries` - Double-entry bookkeeping
   - `journal_entries` - Journal entries
   - `account_balance_snapshots` - Historical balances

7. **notification_db**
   - `notifications` - All notifications
   - `notification_templates` - Email/SMS templates
   - `notification_preferences` - User preferences
   - `notification_batches` - Bulk notifications

8. **reporting_db**
   - `reports` - Generated reports
   - `report_templates` - Report templates
   - `report_subscriptions` - Scheduled reports
   - `regulatory_reports` - Compliance reports

9. **auth_db**
   - `users` - User accounts
   - `refresh_tokens` - JWT refresh tokens
   - `login_history` - Login audit trail
   - `permissions` - System permissions
   - `role_permissions` - Role-based access

### Features

✅ **Enums** - Type-safe status and category fields
✅ **Constraints** - Data integrity checks
✅ **Indexes** - Optimized queries
✅ **Triggers** - Auto-update timestamps
✅ **Foreign Keys** - Referential integrity
✅ **Audit Fields** - created_at, updated_at, created_by
✅ **Soft Deletes** - Status-based deletion
✅ **JSONB** - Flexible metadata storage

## 🔧 Integration with Spring Boot

### Step 1: Add Dependencies to pom.xml

Copy dependencies from `pom-dependencies.xml` to each microservice's `pom.xml`.

```xml
<!-- PostgreSQL + JPA + Flyway -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
```

### Step 2: Update application.yml

Copy the relevant section from `spring-boot-configs.yml` to each microservice.

**Example for Account Service:**

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/account_db
    username: account_user
    password: account_pass_2024
  jpa:
    hibernate:
      ddl-auto: validate
```

### Step 3: Create JPA Entities

**Example: Account Entity**

```java
package com.flanux.account.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "accounts")
@Data
public class Account {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "account_number", unique = true, nullable = false)
    private String accountNumber;
    
    @Column(name = "customer_id", nullable = false)
    private Long customerId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "account_type", nullable = false)
    private AccountType accountType;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "account_status")
    private AccountStatus accountStatus = AccountStatus.ACTIVE;
    
    @Column(precision = 19, scale = 2)
    private BigDecimal balance = BigDecimal.ZERO;
    
    private String currency = "USD";
    
    @Column(name = "interest_rate", precision = 5, scale = 2)
    private BigDecimal interestRate = BigDecimal.ZERO;
    
    @Column(name = "overdraft_limit", precision = 19, scale = 2)
    private BigDecimal overdraftLimit = BigDecimal.ZERO;
    
    @Column(name = "branch_code")
    private String branchCode;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "created_by")
    private String createdBy;
    
    @Column(name = "updated_by")
    private String updatedBy;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

// Enums
enum AccountType {
    SAVINGS, CHECKING, FIXED_DEPOSIT, CURRENT, SALARY
}

enum AccountStatus {
    ACTIVE, INACTIVE, FROZEN, CLOSED, SUSPENDED
}
```

### Step 4: Create Repository

```java
package com.flanux.account.repository;

import com.flanux.account.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AccountRepository extends JpaRepository<Account, Long> {
    
    Optional<Account> findByAccountNumber(String accountNumber);
    
    List<Account> findByCustomerId(Long customerId);
    
    List<Account> findByAccountStatus(AccountStatus status);
    
    boolean existsByAccountNumber(String accountNumber);
}
```

## 🔐 Security Best Practices

### 1. Change Default Passwords

**In Production**, update passwords in:
- `docker/docker-compose.yml`
- `scripts/init-databases.sql`
- Each microservice's `application.yml`

```bash
# Generate strong passwords
openssl rand -base64 32
```

### 2. Use Environment Variables

```yaml
# application.yml
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
```

### 3. Enable SSL/TLS

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/account_db?sslmode=require
```

### 4. Connection Pooling

Already configured with HikariCP (best performance):

```yaml
hikari:
  maximum-pool-size: 10
  minimum-idle: 5
  connection-timeout: 30000
  idle-timeout: 600000
  max-lifetime: 1800000
```

## 📊 Database Users & Permissions

| User | Databases | Permissions |
|------|-----------|-------------|
| `flanux_admin` | All | Full admin access |
| `account_user` | account_db | Full access |
| `customer_user` | customer_db | Full access |
| `loan_user` | loan_db | Full access |
| `card_user` | card_db | Full access |
| `transaction_user` | transaction_db | Full access |
| `ledger_user` | ledger_db | Full access |
| `notification_user` | notification_db | Full access |
| `reporting_user` | reporting_db | Full access |
| `auth_user` | auth_db | Full access |
| `readonly_user` | All | SELECT only |

## 🧪 Testing Database Connection

### From Command Line

```bash
# Test connection
docker exec -it flanux-postgres psql -U account_user -d account_db -c "SELECT 1;"

# List all tables
docker exec -it flanux-postgres psql -U account_user -d account_db -c "\dt"

# Query accounts
docker exec -it flanux-postgres psql -U account_user -d account_db \
  -c "SELECT account_number, balance FROM accounts LIMIT 5;"
```

### From Java

```java
@SpringBootTest
class DatabaseConnectionTest {
    
    @Autowired
    private DataSource dataSource;
    
    @Test
    void testConnection() throws SQLException {
        try (Connection conn = dataSource.getConnection()) {
            assertTrue(conn.isValid(5));
        }
    }
}
```

## 📈 Database Maintenance

### Backup Database

```bash
# Backup single database
docker exec flanux-postgres pg_dump -U flanux_admin account_db > account_db_backup.sql

# Backup all databases
docker exec flanux-postgres pg_dumpall -U flanux_admin > all_databases_backup.sql
```

### Restore Database

```bash
# Restore single database
docker exec -i flanux-postgres psql -U flanux_admin account_db < account_db_backup.sql

# Restore all
docker exec -i flanux-postgres psql -U flanux_admin < all_databases_backup.sql
```

### Monitor Performance

```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Slow queries
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active' AND now() - query_start > interval '5 seconds';
```

## 🚨 Troubleshooting

### Issue: Can't connect to PostgreSQL

```bash
# Check if container is running
docker ps

# Check logs
docker logs flanux-postgres

# Restart container
docker-compose restart postgres
```

### Issue: Permission denied

```bash
# Grant permissions manually
docker exec -it flanux-postgres psql -U flanux_admin -d account_db \
  -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO account_user;"
```

### Issue: Schema not found

```bash
# Run schema scripts manually
docker exec -i flanux-postgres psql -U flanux_admin -d account_db < schemas/01-account-schema.sql
```

## 📚 Next Steps

1. ✅ Database setup complete
2. ⏭️ Add JPA entities to each microservice
3. ⏭️ Implement repositories
4. ⏭️ Add services and controllers
5. ⏭️ Test CRUD operations
6. ⏭️ Move to Kafka setup

## 🔗 Related Files

- `docker/docker-compose.yml` - Docker setup
- `scripts/init-databases.sql` - Database initialization
- `schemas/*.sql` - All schema definitions
- `spring-boot-configs.yml` - Spring Boot configurations
- `pom-dependencies.xml` - Maven dependencies

---

**Ready for Production!** All schemas include proper indexes, constraints, and audit trails. 🎉
