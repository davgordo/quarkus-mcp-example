BEGIN;

DROP SCHEMA IF EXISTS example CASCADE;
CREATE SCHEMA example;
SET search_path TO example;

CREATE TABLE organization (
    organization_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    industry        VARCHAR(100) NOT NULL,
    region          VARCHAR(50) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_organization_name UNIQUE (name)
);

CREATE TABLE department (
    department_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organization_id  BIGINT NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    name             VARCHAR(100) NOT NULL,
    cost_center      VARCHAR(20) NOT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_department_org_name UNIQUE (organization_id, name)
);

CREATE TABLE customer (
    customer_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organization(organization_id) ON DELETE RESTRICT,
    customer_code     VARCHAR(20) NOT NULL,
    name              VARCHAR(150) NOT NULL,
    segment           VARCHAR(50) NOT NULL,
    status            VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'PROSPECT', 'INACTIVE')),
    annual_revenue    NUMERIC(14,2),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_code UNIQUE (customer_code)
);

CREATE TABLE customer_contact (
    contact_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id       BIGINT NOT NULL REFERENCES customer(customer_id) ON DELETE CASCADE,
    first_name        VARCHAR(80) NOT NULL,
    last_name         VARCHAR(80) NOT NULL,
    email             VARCHAR(200) NOT NULL,
    phone             VARCHAR(30),
    role_title        VARCHAR(100),
    is_primary        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_contact_email UNIQUE (email)
);

CREATE TABLE app_user (
    user_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id     BIGINT NOT NULL REFERENCES department(department_id) ON DELETE RESTRICT,
    username          VARCHAR(50) NOT NULL,
    full_name         VARCHAR(150) NOT NULL,
    email             VARCHAR(200) NOT NULL,
    job_title         VARCHAR(100) NOT NULL,
    user_role         VARCHAR(30) NOT NULL CHECK (user_role IN ('ADMIN', 'MANAGER', 'ANALYST', 'ENGINEER', 'SALES')),
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_app_user_username UNIQUE (username),
    CONSTRAINT uq_app_user_email UNIQUE (email)
);

CREATE TABLE project (
    project_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id        BIGINT NOT NULL REFERENCES customer(customer_id) ON DELETE RESTRICT,
    owner_user_id      BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE RESTRICT,
    name               VARCHAR(150) NOT NULL,
    project_type       VARCHAR(50) NOT NULL,
    status             VARCHAR(20) NOT NULL CHECK (status IN ('PLANNING', 'ACTIVE', 'ON_HOLD', 'COMPLETED', 'CANCELLED')),
    start_date         DATE NOT NULL,
    target_end_date    DATE,
    budget_amount      NUMERIC(12,2),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE project_assignment (
    project_id         BIGINT NOT NULL REFERENCES project(project_id) ON DELETE CASCADE,
    user_id            BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE RESTRICT,
    assignment_role    VARCHAR(50) NOT NULL,
    allocation_pct     NUMERIC(5,2) NOT NULL CHECK (allocation_pct > 0 AND allocation_pct <= 100),
    assigned_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, user_id)
);

CREATE TABLE task (
    task_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id          BIGINT NOT NULL REFERENCES project(project_id) ON DELETE CASCADE,
    assigned_user_id    BIGINT REFERENCES app_user(user_id) ON DELETE SET NULL,
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    priority            VARCHAR(10) NOT NULL CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status              VARCHAR(20) NOT NULL CHECK (status IN ('OPEN', 'IN_PROGRESS', 'BLOCKED', 'DONE')),
    estimate_hours      NUMERIC(8,2),
    due_date            DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_comment (
    comment_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id             BIGINT NOT NULL REFERENCES task(task_id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE RESTRICT,
    comment_text        TEXT NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE invoice (
    invoice_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         BIGINT NOT NULL REFERENCES customer(customer_id) ON DELETE RESTRICT,
    project_id          BIGINT REFERENCES project(project_id) ON DELETE SET NULL,
    invoice_number      VARCHAR(30) NOT NULL,
    invoice_date        DATE NOT NULL,
    due_date            DATE NOT NULL,
    status              VARCHAR(20) NOT NULL CHECK (status IN ('DRAFT', 'SENT', 'PAID', 'VOID')),
    currency_code       CHAR(3) NOT NULL DEFAULT 'USD',
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number)
);

CREATE TABLE invoice_line (
    invoice_line_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id          BIGINT NOT NULL REFERENCES invoice(invoice_id) ON DELETE CASCADE,
    line_number         INTEGER NOT NULL,
    item_description    VARCHAR(200) NOT NULL,
    quantity            NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price          NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    tax_rate            NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (tax_rate >= 0),
    CONSTRAINT uq_invoice_line UNIQUE (invoice_id, line_number)
);

INSERT INTO organization (name, industry, region) VALUES
('Northwind Advisory', 'Consulting', 'North America'),
('BluePeak Retail', 'Retail', 'North America'),
('Summit Health Partners', 'Healthcare', 'North America');

INSERT INTO department (organization_id, name, cost_center) VALUES
(1, 'Sales', 'CC100'),
(1, 'Engineering', 'CC200'),
(1, 'Operations', 'CC300'),
(2, 'Sales', 'CC110'),
(2, 'Support', 'CC120'),
(3, 'Programs', 'CC130');

INSERT INTO customer (organization_id, customer_code, name, segment, status, annual_revenue) VALUES
(1, 'CUST-1001', 'Acme Manufacturing', 'Enterprise', 'ACTIVE', 2500000.00),
(1, 'CUST-1002', 'BrightPath Logistics', 'Mid-Market', 'ACTIVE', 980000.00),
(2, 'CUST-1003', 'Greenfield Schools', 'Public Sector', 'PROSPECT', 450000.00),
(3, 'CUST-1004', 'Horizon Clinics', 'Enterprise', 'ACTIVE', 1750000.00);

INSERT INTO customer_contact (customer_id, first_name, last_name, email, phone, role_title, is_primary) VALUES
(1, 'Alicia', 'Stone', 'alicia.stone@acme.example', '555-0101', 'Director of Operations', TRUE),
(1, 'Marcus', 'Cole', 'marcus.cole@acme.example', '555-0102', 'IT Manager', FALSE),
(2, 'Priya', 'Patel', 'priya.patel@brightpath.example', '555-0103', 'VP Logistics', TRUE),
(3, 'Sandra', 'Lopez', 'sandra.lopez@greenfield.example', '555-0104', 'Procurement Lead', TRUE),
(4, 'Jordan', 'Kim', 'jordan.kim@horizon.example', '555-0105', 'CIO', TRUE);

INSERT INTO app_user (department_id, username, full_name, email, job_title, user_role) VALUES
(1, 'jreyes', 'Julia Reyes', 'julia.reyes@demo.example', 'Account Executive', 'SALES'),
(2, 'mnguyen', 'Minh Nguyen', 'minh.nguyen@demo.example', 'Engineering Manager', 'MANAGER'),
(2, 'tcarter', 'Taylor Carter', 'taylor.carter@demo.example', 'Software Engineer', 'ENGINEER'),
(3, 'rshah', 'Ravi Shah', 'ravi.shah@demo.example', 'Operations Analyst', 'ANALYST'),
(4, 'ebrooks', 'Emma Brooks', 'emma.brooks@demo.example', 'Regional Sales Manager', 'MANAGER'),
(5, 'kross', 'Kendall Ross', 'kendall.ross@demo.example', 'Support Engineer', 'ENGINEER'),
(6, 'dlee', 'Dana Lee', 'dana.lee@demo.example', 'Program Director', 'ADMIN');

INSERT INTO project (customer_id, owner_user_id, name, project_type, status, start_date, target_end_date, budget_amount) VALUES
(1, 1, 'Acme CRM Rollout', 'Implementation', 'ACTIVE', DATE '2026-01-15', DATE '2026-06-30', 180000.00),
(2, 5, 'BrightPath Analytics Upgrade', 'Upgrade', 'ACTIVE', DATE '2026-02-01', DATE '2026-05-15', 95000.00),
(4, 7, 'Horizon Data Integration', 'Integration', 'PLANNING', DATE '2026-03-01', DATE '2026-08-31', 220000.00),
(3, 1, 'Greenfield Discovery Workshop', 'Assessment', 'COMPLETED', DATE '2025-11-10', DATE '2025-12-05', 15000.00);

INSERT INTO project_assignment (project_id, user_id, assignment_role, allocation_pct) VALUES
(1, 1, 'Executive Sponsor', 20.00),
(1, 2, 'Project Lead', 40.00),
(1, 3, 'Implementation Engineer', 80.00),
(1, 4, 'Reporting Analyst', 30.00),
(2, 5, 'Account Lead', 35.00),
(2, 6, 'Support Engineer', 60.00),
(3, 7, 'Program Sponsor', 25.00),
(3, 2, 'Technical Advisor', 15.00),
(4, 1, 'Account Lead', 20.00),
(4, 4, 'Business Analyst', 50.00);

INSERT INTO task (project_id, assigned_user_id, title, description, priority, status, estimate_hours, due_date) VALUES
(1, 2, 'Finalize requirements', 'Confirm functional and reporting requirements with stakeholders.', 'HIGH', 'IN_PROGRESS', 24.00, DATE '2026-03-20'),
(1, 3, 'Configure customer profiles', 'Set up profile schema and migration scripts.', 'MEDIUM', 'OPEN', 16.00, DATE '2026-03-25'),
(1, 4, 'Build executive dashboard', 'Create KPI dashboard for leadership review.', 'HIGH', 'OPEN', 20.00, DATE '2026-03-28'),
(2, 6, 'Validate source connectors', 'Test connectivity to warehouse and TMS endpoints.', 'HIGH', 'DONE', 12.00, DATE '2026-03-05'),
(2, 6, 'Document cutover runbook', 'Prepare operational runbook for go-live.', 'MEDIUM', 'IN_PROGRESS', 10.00, DATE '2026-03-18'),
(3, 2, 'Draft integration architecture', 'Initial architecture for inbound and outbound interfaces.', 'CRITICAL', 'OPEN', 30.00, DATE '2026-03-30'),
(4, 4, 'Summarize workshop findings', 'Compile discovery notes and recommendations.', 'LOW', 'DONE', 8.00, DATE '2025-12-03');

INSERT INTO task_comment (task_id, user_id, comment_text) VALUES
(1, 2, 'Met with customer operations lead and captured open questions.'),
(1, 1, 'Need final approval on reporting scope before sign-off.'),
(2, 3, 'Waiting on sample customer export from Acme IT.'),
(4, 6, 'All connectors validated successfully in test environment.'),
(6, 7, 'Please include security and audit requirements in the first draft.');

INSERT INTO invoice (customer_id, project_id, invoice_number, invoice_date, due_date, status, currency_code) VALUES
(1, 1, 'INV-2026-0001', DATE '2026-02-01', DATE '2026-03-03', 'PAID', 'USD'),
(1, 1, 'INV-2026-0002', DATE '2026-03-01', DATE '2026-03-31', 'SENT', 'USD'),
(2, 2, 'INV-2026-0003', DATE '2026-02-15', DATE '2026-03-17', 'PAID', 'USD'),
(4, 3, 'INV-2026-0004', DATE '2026-03-05', DATE '2026-04-04', 'DRAFT', 'USD');

INSERT INTO invoice_line (invoice_id, line_number, item_description, quantity, unit_price, tax_rate) VALUES
(1, 1, 'Project kickoff and planning', 1, 12000.00, 8.25),
(1, 2, 'Requirements workshops', 3, 2500.00, 8.25),
(2, 1, 'Configuration sprint 1', 1, 15000.00, 8.25),
(2, 2, 'Dashboard design', 1, 5000.00, 8.25),
(3, 1, 'Connector validation services', 1, 9000.00, 8.25),
(3, 2, 'Operational readiness review', 1, 3500.00, 8.25),
(4, 1, 'Architecture assessment retainer', 1, 18000.00, 8.25);

COMMIT;
