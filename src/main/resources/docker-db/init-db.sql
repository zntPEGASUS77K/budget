CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Création des séquences
CREATE SEQUENCE IF NOT EXISTS user_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS category_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS transaction_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS budget_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS account_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS shared_budget_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS audit_log_id_seq START 1;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
                                     id BIGINT PRIMARY KEY DEFAULT nextval('user_id_seq'),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_encrypted TEXT,
    default_currency VARCHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Table des catégories
CREATE TABLE IF NOT EXISTS categories (
                                          id BIGINT PRIMARY KEY DEFAULT nextval('category_id_seq'),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    icon VARCHAR(50),
    parent_id BIGINT REFERENCES categories(id),
    user_id BIGINT REFERENCES users(id),
    is_system BOOLEAN DEFAULT false,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Table des comptes
CREATE TABLE IF NOT EXISTS accounts (
                                        id BIGINT PRIMARY KEY DEFAULT nextval('account_id_seq'),
    user_id BIGINT NOT NULL REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('CURRENT', 'SAVINGS', 'CREDIT_CARD')),
    balance DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Table des transactions
CREATE TABLE IF NOT EXISTS transactions (
                                            id BIGINT PRIMARY KEY DEFAULT nextval('transaction_id_seq'),
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    transaction_date TIMESTAMP NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id),
    category_id BIGINT NOT NULL REFERENCES categories(id),
    account_id BIGINT REFERENCES accounts(id),
    location JSONB,
    type VARCHAR(20) NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    receipt_url VARCHAR(500),
    receipt_metadata JSONB,
    tags TEXT[],
    is_synced BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Table des budgets
CREATE TABLE IF NOT EXISTS budgets (
                                       id BIGINT PRIMARY KEY DEFAULT nextval('budget_id_seq'),
    user_id BIGINT NOT NULL REFERENCES users(id),
    category_id BIGINT NOT NULL REFERENCES categories(id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('MONTHLY', 'YEARLY')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    alert_threshold DECIMAL(5,2) DEFAULT 80.00 CHECK (alert_threshold BETWEEN 0 AND 100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (start_date <= end_date)
    );

-- Table budgets partagés
CREATE TABLE IF NOT EXISTS shared_budgets (
                                              id BIGINT PRIMARY KEY DEFAULT nextval('shared_budget_id_seq'),
    budget_id BIGINT NOT NULL REFERENCES budgets(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    role VARCHAR(20) NOT NULL CHECK (role IN ('OWNER', 'CONTRIBUTOR', 'VIEWER')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(budget_id, user_id)
    );

-- Table des transactions récurrentes
CREATE TABLE IF NOT EXISTS recurring_transactions (
                                                      id BIGINT PRIMARY KEY DEFAULT nextval('recurring_transaction_id_seq'),
    user_id BIGINT NOT NULL REFERENCES users(id),
    category_id BIGINT NOT NULL REFERENCES categories(id),
    account_id BIGINT REFERENCES accounts(id),
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
CREATE SEQUENCE IF NOT EXISTS recurring_transaction_id_seq START 1;

-- Table des logs d'audit
CREATE TABLE IF NOT EXISTS audit_logs (
                                          id BIGINT PRIMARY KEY DEFAULT nextval('audit_log_id_seq'),
    user_id BIGINT REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_tags ON transactions USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_transactions_recent ON transactions(user_id, transaction_date) WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 year';
CREATE INDEX IF NOT EXISTS idx_budgets_user_period ON budgets(user_id, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_budgets_budget_user ON shared_budgets(budget_id, user_id);

-- Insertion des catégories système par défaut
INSERT INTO categories (name, description, color, icon, is_system) VALUES
                                                                       ('Alimentation', 'Courses, restaurants, nourriture', '#FF6B6B', 'utensils', true),
                                                                       ('Transport', 'Essence, transports publics, taxi', '#4ECDC4', 'car', true),
                                                                       ('Logement', 'Loyer, électricité, internet', '#45B7D1', 'home', true),
                                                                       ('Santé', 'Médecin, pharmacie, assurance', '#96CEB4', 'heart', true),
                                                                       ('Loisirs', 'Cinéma, sport, hobbies', '#FFEAA7', 'gamepad', true),
                                                                       ('Shopping', 'Vêtements, technologie, divers', '#DDA0DD', 'shopping-bag', true),
                                                                       ('Éducation', 'Livres, formations, cours', '#98D8C8', 'book', true),
                                                                       ('Salaire', 'Revenus du travail', '#00B894', 'dollar-sign', true),
                                                                       ('Investissement', 'Dividendes, plus-values', '#6C5CE7', 'trending-up', true),
                                                                       ('Autre', 'Transactions diverses', '#A0A0A0', 'more-horizontal', true)
    ON CONFLICT DO NOTHING;

-- Triggers pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour audit des transactions
CREATE OR REPLACE FUNCTION log_transaction_changes()
RETURNS TRIGGER AS $$
BEGIN
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details)
VALUES (NEW.user_id,
        CASE WHEN TG_OP = 'INSERT' THEN 'CREATE'
             WHEN TG_OP = 'UPDATE' THEN 'UPDATE'
             ELSE 'DELETE' END,
        'TRANSACTION',
        NEW.id,
        jsonb_build_object('old', OLD, 'new', NEW));
RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER transaction_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW EXECUTE FUNCTION log_transaction_changes();