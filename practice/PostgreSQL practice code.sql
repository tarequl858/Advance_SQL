/* ============================================================
   PostgreSQL Master Practice Script
   - Fully formatted, heavily commented, educational version
   - Contains: DDL, DML, DCL, TCL, schema design, indexes,
     CTEs, JSON/JSONB, triggers, functions/procedures, materialized views
   - Run in a development DB; DO NOT run as-is in production.
   ============================================================ */


-- ------------------------------------------------------------
-- CLEANUP SECTION
-- Remove previously-created objects so the script is idempotent
-- ------------------------------------------------------------
DROP VIEW IF EXISTS price_info;
DROP TABLE IF EXISTS product_details;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS products;        -- we'll recreate products later
DROP TABLE IF EXISTS purchese;        -- kept original spelling to match references
DROP TABLE IF EXISTS products1;
DROP TABLE IF EXISTS products2;
DROP TABLE IF EXISTS drinks;          -- renamed variant used later
DROP TABLE IF EXISTS employee2;
DROP TABLE IF EXISTS Employees3;
DROP TABLE IF EXISTS Departments;
DROP ROLE IF EXISTS tareq_user;


-- ============================================================
-- SECTION: Basic Products / Suppliers (DDL + DML + Queries)
-- Purpose: demonstrate table creation, insertion, simple queries,
-- joins, aggregates, and basic transactional control.
-- ============================================================

-- Create a simple products table (schema definition)
CREATE TABLE products (
    name           VARCHAR(50),      -- product name
    items_in_stock INT,              -- integer stock count
    price          NUMERIC(7,2)      -- price (precision: up to 7 digits, 2 decimals)
);

-- Start a transaction to demonstrate BEGIN / SAVEPOINT / ROLLBACK / COMMIT
BEGIN;

-- Insert sample rows into products (DML)
INSERT INTO products (name, items_in_stock, price)
VALUES
    ('Apples',  100, 25.00),         -- explicitly show cents as .00
    ('Bananas',  32, 10.00),
    ('Cherries', 74,  2.50);

-- Create a savepoint so we can intentionally roll back part of the transaction later
SAVEPOINT sp1;

-- Verify table contents
SELECT * FROM products;

-- Calculate inventory value per product (simple derived column)
SELECT name,
       items_in_stock,
       price,
       items_in_stock * price AS inventory_value
FROM products;


-- Create a suppliers table that references products by name (text-match example)
CREATE TABLE suppliers (
    name               VARCHAR(70),   -- supplier name
    product_name       VARCHAR(50),   -- product this supplier provides (text)
    unit_price         NUMERIC(7,2),  -- supplier's unit price
    last_delivery_date DATE           -- last delivery date
);

-- Insert sample suppliers
INSERT INTO suppliers (name, product_name, unit_price, last_delivery_date) VALUES
    ('ACME Fruits Ltd', 'Bananas', 8.50, '2023-07-23'),
    ('Green Thumb Corp.', 'Spinach', 5.95, '2023-07-24'),
    ('Jolly Grocers', 'Apples', 23.80, '2023-07-24');

-- Quick peek at suppliers
SELECT * FROM suppliers;


-- ========= JOINS & ANALYSIS =========
-- INNER JOIN: return rows where product exists in both tables
SELECT p.*, s.*
FROM products p
JOIN suppliers s
  ON p.name = s.product_name;

-- Project specific columns with aliases for clarity
SELECT
    s.name                AS supplier_name,
    p.name                AS product_name,
    p.price               AS sale_price,
    s.unit_price          AS purchase_price,
    p.items_in_stock,
    s.last_delivery_date
FROM products p
JOIN suppliers s
  ON p.name = s.product_name;

-- FULL OUTER JOIN: preserve rows from both sides even when unmatched
SELECT
    s.name       AS supplier_name,
    p.name       AS product_name,
    p.price,
    s.unit_price AS purchase_price,
    p.items_in_stock,
    s.last_delivery_date
FROM products p
FULL OUTER JOIN suppliers s
  ON p.name = s.product_name
ORDER BY supplier_name;  -- ordering helps readability when results have many NULLs


-- Aggregation example: total inventory value across all products
SELECT SUM(price * items_in_stock) AS total_inventory_value
FROM products;

-- Subquery example: find product(s) with minimum price
SELECT name, price
FROM products
WHERE price = (SELECT MIN(price) FROM products);


-- Insert additional suppliers to expand dataset
INSERT INTO suppliers (name, product_name, unit_price, last_delivery_date)
VALUES
    ('Planet Farms',  'Apples', 24.10, '2023-07-25'),
    ('City Merchants', 'Bananas', 9.00, '2023-07-25');

-- GROUP BY example: per-product supplier stats
SELECT
    product_name,
    COUNT(name)   AS num_suppliers,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    AVG(unit_price) AS avg_price
FROM suppliers
GROUP BY product_name;


-- JOIN + GROUP + HAVING example:
-- Compare average purchase price (supplier) vs sale price (product),
-- show only products whose sale price is greater than 20.
SELECT
    s.product_name,
    AVG(s.unit_price) AS avg_purchase_price,
    p.price           AS sale_price
FROM products p
JOIN suppliers s
  ON p.name = s.product_name
GROUP BY s.product_name, p.price
HAVING p.price > 20
ORDER BY sale_price DESC;


-- ========= TRANSACTION CONTROL (TCL) =========
-- Demonstrate update, rollback to savepoint, delete, then commit.

-- Update a row (we will undo this using ROLLBACK TO SAVEPOINT)
UPDATE products
SET price = 3.00
WHERE name = 'Cherries';

-- Undo everything back to savepoint 'sp1' (this reverts the price update)
ROLLBACK TO sp1;

-- Remove bananas from the products table (this will be committed below)
DELETE FROM products
WHERE name = 'Bananas';

-- Persist remaining changes
COMMIT;


-- ============================================================
-- SECTION: Security (DCL) - Roles & Privileges
-- Purpose: create a role, grant and revoke privileges (demo only)
-- ============================================================

-- Create a user/role (example only). Replace '12345' with a secure secret in real life.
CREATE ROLE tareq_user WITH LOGIN PASSWORD '12345';

-- Grant and revoke privileges: demonstrate how to restrict access
GRANT SELECT, INSERT ON suppliers TO tareq_user;
GRANT SELECT ON products TO tareq_user;

-- Revoke the INSERT right on suppliers to show privilege revocation
REVOKE INSERT ON suppliers FROM tareq_user;


-- Verify products content after commit
SELECT * FROM products;


-- ============================================================
-- SECTION: purchese table (kept original spelling intentionally)
-- Purpose: demonstrate a different table used by view/function examples
-- ============================================================

CREATE TABLE purchese (
    name           VARCHAR(50),
    items_in_stock INT,
    price          NUMERIC(7,2)
);

INSERT INTO purchese (name, items_in_stock, price)
VALUES
    ('Apples', 100, 25.00),
    ('Bananas', 32, 10.00),
    ('Cherries', 74, 2.50);

-- Show purchese contents
SELECT * FROM purchese;

-- Show suppliers again for cross-checking
SELECT * FROM suppliers;


-- ============================================================
-- SECTION: Views
-- Purpose: create reusable logical query (profit per unit view)
-- ============================================================

CREATE OR REPLACE VIEW price_info AS
SELECT
    s.name               AS supplier_name,
    s.product_name,
    p.price              AS selling_price,
    s.unit_price         AS purchase_price,
    (p.price - s.unit_price) AS profit_per_unit
FROM suppliers s
JOIN purchese p
  ON s.product_name = p.name;   -- join on the 'purchese' table

-- Query the view (act like a table)
SELECT * FROM price_info;


-- ============================================================
-- SECTION: Window Functions (advanced aggregation)
-- Purpose: show partitioned calculations and named windows
-- ============================================================

-- Per-product rolling/partitioned average (ordered)
SELECT
    product_name,
    unit_price,
    AVG(unit_price) OVER (PARTITION BY product_name ORDER BY unit_price DESC) AS avg_price
FROM suppliers
ORDER BY avg_price DESC, unit_price DESC;

-- Use a named WINDOW to compute AVG and STDDEV per partition
SELECT
    product_name,
    unit_price,
    AVG(unit_price)  OVER w AS avg_unit_price,
    STDDEV(unit_price) OVER w AS sd_unit_price
FROM suppliers
WINDOW w AS (PARTITION BY product_name);


-- ============================================================
-- SECTION: Table Inheritance (Postgres feature)
-- Purpose: illustrate inheritance — rarely used in modern apps,
-- but useful to understand how Postgres allows "is-a" relationships.
-- ============================================================

CREATE TABLE product_details (
    relative_size VARCHAR(20),
    shelf_life    INTERVAL
) INHERITS (suppliers);   -- inherits columns: name, product_name, unit_price, last_delivery_date

-- Insert into child table (inherited columns + new ones)
INSERT INTO product_details (name, product_name, unit_price, last_delivery_date, relative_size, shelf_life)
VALUES ('ACME Supplier', 'Pomegranates', 32.00, '2023-11-01', 'small', INTERVAL '2 weeks');

-- Query inherited table (shows both inherited and new columns)
SELECT * FROM product_details;


-- ============================================================
-- SECTION: String & Type Examples
-- Purpose: quoting, escape formats, explicit casting
-- ============================================================

-- Escaping single quote inside a single-quoted string
SELECT 'jane''s book' AS book;           -- returns: jane's book

-- Dollar-quoting avoids escaping internal single quotes
SELECT $$jane's book$$ AS book1;

-- E'' extended escape string with tab/newline escapes
SELECT E'some\trandom\ntext\n\nthere' AS text_value;

-- Explicit cast example: string -> numeric(5,2)
SELECT '123'::numeric(5,2) AS numeric_value;  -- shows 123.00


-- ============================================================
-- SECTION: SQL FUNCTION (returns table)
-- Purpose: wrapped query that returns rows as a table result
-- ============================================================

CREATE OR REPLACE FUNCTION due_for_purchases()
RETURNS TABLE (name TEXT, num_items_left INT) AS
$$
    SELECT name, items_in_stock
    FROM purchese
    WHERE items_in_stock > 50
    ORDER BY items_in_stock;
$$
LANGUAGE SQL;

-- Execute the function as a table
SELECT * FROM due_for_purchases();


-- ============================================================
-- SECTION: products1 demo (defaults + drop)
-- Purpose: default values and cleanup pattern
-- ============================================================

CREATE TABLE products1 (
    name       TEXT,
    perishable BOOLEAN DEFAULT TRUE,
    date       DATE DEFAULT CURRENT_DATE
);

INSERT INTO products1 (name) VALUES ('Mutton');
SELECT * FROM products1;
DROP TABLE products1;  -- cleanup after demonstration


-- ============================================================
-- SECTION: Carefully-created products2 (constraints, generated col)
-- Purpose: show CHECK, PRIMARY KEY, GENERATED stored column, FK usage
-- NOTES:
--  - Generated column 'duration' computed from end_time - start_time
--  - FOREIGN KEY references purchese(name) — purchese must exist
-- ============================================================

CREATE TABLE products2 (
    name        TEXT PRIMARY KEY,                           -- PK ensures uniqueness & NOT NULL
    perishable  BOOLEAN DEFAULT TRUE,
    date        DATE DEFAULT CURRENT_DATE,
    start_time  TIMESTAMP,
    end_time    TIMESTAMP,
    duration    INTERVAL GENERATED ALWAYS AS (end_time - start_time) STORED,
    price       NUMERIC(5,2) CONSTRAINT positive_price CHECK (price > 0),
    CONSTRAINT valid_name_not_null CHECK (name IS NOT NULL),   -- explicit constraint for clarity
    FOREIGN KEY (name) REFERENCES purchese(name)              -- referential integrity to purchese
);

-- Example insertion (duration will be computed automatically)
INSERT INTO products2 (name, start_time, end_time, price)
VALUES ('Mutton', '2023-08-01 09:12', '2023-08-01 10:55', 20.00);

SELECT * FROM products2;


-- ============================================================
-- SECTION: ALTER TABLE examples (add/drop/constraints/renames)
-- Purpose: common DDL operations you'll use in migrations
-- ============================================================

-- Add a column with a DEFAULT value
ALTER TABLE products2 ADD COLUMN serving_quantity_ml INTEGER DEFAULT 350;

-- Drop that column when it's no longer needed
ALTER TABLE products2 DROP COLUMN serving_quantity_ml;

-- Add a new column used in a UNIQUE constraint
ALTER TABLE products2 ADD COLUMN serving_temp INTEGER;   -- e.g., degrees Celsius

-- Add a multi-column UNIQUE constraint
ALTER TABLE products2 ADD CONSTRAINT products2_name_serving_temp_key UNIQUE (name, serving_temp);

-- Make column NOT NULL (possible only if existing rows satisfy the constraint)
ALTER TABLE products2 ALTER COLUMN name SET NOT NULL;

-- Drop NOT NULL constraint
ALTER TABLE products2 ALTER COLUMN name DROP NOT NULL;

-- Set and later drop a DEFAULT value on a column
ALTER TABLE products2 ALTER COLUMN name SET DEFAULT 'default_name';
ALTER TABLE products2 ALTER COLUMN name DROP DEFAULT;

-- Change column type (careful: money type has locale-specific semantics)
ALTER TABLE products2 ALTER COLUMN price TYPE money USING (price::money);

-- Rename column
ALTER TABLE products2 RENAME COLUMN price TO unit_price;

-- Rename the table (from products2 to drinks)
ALTER TABLE products2 RENAME TO drinks;

-- Select from newly renamed table with LIMIT/OFFSET
SELECT * FROM drinks ORDER BY unit_price LIMIT 2 OFFSET 2;


-- ============================================================
-- SECTION: Employee / Departments demo & JOIN varieties
-- Purpose: illustrate RIGHT JOIN, FULL OUTER JOIN, CROSS JOIN, SELF JOIN
-- ============================================================

DROP TABLE IF EXISTS employee2;

CREATE TABLE employee2 (
    employee_id INT PRIMARY KEY,
    first_name  VARCHAR(20) NOT NULL,
    last_name   VARCHAR(20) NOT NULL,
    email       VARCHAR(50),
    department  VARCHAR(20),
    salary      NUMERIC(10,2),
    joining_date DATE,
    age         INT
);

SELECT * FROM employee2;  -- empty table structure

-- CSV import guidance (commented): use \copy in psql for client-side import
-- \copy employee2(employee_id, first_name, last_name, email, department, salary, joining_date, age) FROM 'D:\SQL\CSV\employee_data.csv' DELIMITER ',' CSV HEADER;

-- Recreate higher-level products table with surrogate id and sample rows
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,   -- auto-incrementing surrogate id
    product_name  VARCHAR(100),
    category      VARCHAR(50),
    price         NUMERIC(10,2),
    quantity      INT,
    added_date    DATE,
    discount_rate NUMERIC(5,2),
    discount_price NUMERIC(10,2)         -- nullable discount price column
);

INSERT INTO products (product_name, category, price, quantity, added_date, discount_rate) VALUES
('Laptop',     'Electronics', 75000.50, 10, '2024-01-15', 10.00),
('Smartphone', 'Electronics', 45000.99, 25, '2024-02-20', 5.00),
('Headphones', 'Accessories', 1500.75,  50, '2024-03-05', 15.00),
('Office Chair','Furniture',  5500.00,  20, '2023-12-01', 20.00),
('Desk',       'Furniture',  8000.00,  15, '2023-11-20', 12.00),
('Monitor',    'Electronics',12000.00,  8, '2024-01-10', 8.00),
('Printer',    'Electronics', 9500.50,  5, '2024-02-01', 7.50),
('Mouse',      'Accessories', 750.00,  40, '2024-03-18', 10.00),
('Keyboard',   'Accessories',1250.00,  35, '2024-03-18', 10.00),
('Tablet',     'Electronics',30000.00, 12, '2024-02-28', 5.00);

SELECT * FROM products;


-- ============================================================
-- SECTION: Date/Time functions examples (practical uses)
-- Purpose: demonstrate NOW(), CURRENT_DATE, AGE(), EXTRACT(), TO_CHAR(), DATE_TRUNC()
-- ============================================================

-- Current timestamp
SELECT NOW() AS current_datetime;

-- Current date
SELECT CURRENT_DATE AS today_date;

-- Difference (days) between current date and product added_date
SELECT added_date,
       CURRENT_DATE AS current_date,
       (CURRENT_DATE - added_date) AS days_difference
FROM products;

-- Extract parts of dates
SELECT product_name,
       EXTRACT(YEAR  FROM added_date) AS year_added,
       EXTRACT(MONTH FROM added_date) AS month_added,
       EXTRACT(DAY   FROM added_date) AS day_added
FROM products;

-- AGE() returns an interval between two dates (useful for "time since")
SELECT product_name,
       AGE(CURRENT_DATE, added_date) AS age_since_added
FROM products;

-- Format dates as strings (TO_CHAR)
SELECT product_name,
       TO_CHAR(added_date, 'MM-DD-YYYY') AS formatted_date
FROM products;

-- DATE_PART() numeric extraction (alternative to EXTRACT)
SELECT product_name, added_date,
       DATE_PART('month', added_date) AS month_number
FROM products;

-- DATE_TRUNC() to normalize to week/month/day boundaries
SELECT product_name, added_date,
       DATE_TRUNC('week', added_date) AS week_start,
       DATE_PART('isodow', added_date) AS day_of_week
FROM products;

-- Interval arithmetic: add 6 months to added_date
SELECT product_name, added_date,
       added_date + INTERVAL '6 months' AS new_date
FROM products;

-- Current time (time-of-day only)
SELECT CURRENT_TIME AS current_time;

-- Convert a string to a DATE using a specific format mask
SELECT TO_DATE('28-11-2024', 'DD-MM-YYYY') AS converted_date;


-- ============================================================
-- SECTION: CASE expressions (conditional logic examples)
-- Purpose: categorize values using CASE expressions
-- ============================================================

-- Price category classification
SELECT product_name, price,
       CASE
           WHEN price >= 50000 THEN 'Expensive'
           WHEN price >= 10000 AND price <= 49999 THEN 'Moderate'
           ELSE 'Affordable'
       END AS price_category
FROM products;

-- Stock status classification
SELECT product_name, quantity,
       CASE
           WHEN quantity >= 10 THEN 'In Stock'
           WHEN quantity BETWEEN 6 AND 9 THEN 'Limited stock'
           ELSE 'Out of stock soon'
       END AS stock_status
FROM products;

-- Category classification using LIKE
SELECT product_name, category,
       CASE
           WHEN category LIKE 'Electronics%' THEN 'Electronic Item'
           WHEN category LIKE 'Furniture%' THEN 'Furniture Item'
           ELSE 'Accessory Item'
       END AS category_status
FROM products;


-- ============================================================
-- SECTION: Working with discount_price and COALESCE
-- Purpose: show how to compute / fallback values when NULLs present
-- ============================================================

-- Set discount_price to NULL for specific products (simulate missing discounts)
UPDATE products
SET discount_price = NULL
WHERE product_name IN ('Laptop', 'Desk');

-- Compute discount_price for other items (example: 10% off)
UPDATE products
SET discount_price = price * 0.9
WHERE product_name NOT IN ('Laptop', 'Desk');

-- Display price columns
SELECT product_name, price, discount_price
FROM products;

-- Use COALESCE to fall back to price when discount_price is NULL
SELECT product_name,
       COALESCE(discount_price, price) AS final_price
FROM products;


-- ============================================================
-- SECTION: Employee / Departments — create & demo joins
-- ============================================================

CREATE TABLE Employees3 (
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    department_id INT
);

INSERT INTO Employees3 (first_name, last_name, department_id)
VALUES
    ('Rahul',  'Sharma', 101),
    ('Priya',  'Mehta',  102),
    ('Ankit',  'Verma',  103),
    ('Simran', 'Kaur',   NULL),
    ('Aman',   'Singh',  101);

SELECT * FROM Employees3;

CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50)
);

INSERT INTO Departments (department_id, department_name)
VALUES
    (101, 'Sales'),
    (102, 'Marketing'),
    (103, 'IT'),
    (104, 'HR');

SELECT * FROM Departments;

-- RIGHT JOIN: show all departments plus matching employees (departments always shown)
SELECT e.employee_id, e.first_name, e.last_name,
       d.department_id, d.department_name
FROM Employees3 e
RIGHT JOIN Departments d
  ON e.department_id = d.department_id;

-- FULL OUTER JOIN: show all employees and departments, matched where possible
SELECT e.employee_id, e.first_name, e.last_name,
       d.department_id, d.department_name
FROM Employees3 e
FULL OUTER JOIN Departments d
  ON e.department_id = d.department_id;

-- CROSS JOIN: Cartesian product (use sparingly)
SELECT e.first_name, e.last_name, d.department_name
FROM Employees3 e
CROSS JOIN Departments d;

-- SELF JOIN: pair employees in same department (exclude self-pairing)
SELECT e1.first_name AS employee_name1,
       e2.first_name AS employee_name2,
       d.department_name
FROM Employees3 e1
JOIN Employees3 e2
  ON e1.department_id = e2.department_id
  AND e1.employee_id != e2.employee_id
JOIN Departments d
  ON e1.department_id = d.department_id;


-- ============================================================
-- ADVANCED SECTION START
-- Schema design, Indexing, CTEs, JSONB, Triggers, Procedures,
-- Materialized views — full examples and explanations.
-- ============================================================


/* ===========================================================
   SCHEMA DESIGN (namespaces)
   - Use schemas to organize logical areas (sales, hr, analytics)
   - Schemas isolate permissions and make large DBs manageable
   =========================================================== */

DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS analytics CASCADE;

CREATE SCHEMA sales;
CREATE SCHEMA hr;
CREATE SCHEMA analytics;

-- Create an orders table in the sales schema
CREATE TABLE sales.orders (
    order_id     SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    order_date    DATE DEFAULT CURRENT_DATE,
    total_amount  NUMERIC(10,2) NOT NULL CHECK (total_amount > 0)  -- validate positive amounts
);

-- HR employees table inside hr schema
CREATE TABLE hr.employees (
    emp_id    SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    department VARCHAR(50),
    salary    NUMERIC(10,2),
    hire_date DATE DEFAULT CURRENT_DATE
);

SELECT * FROM sales.orders;
SELECT * FROM hr.employees;


-- ===========================================================
-- INDEXING FOR PERFORMANCE
-- - Create B-tree indexes (default) for equality/range queries
-- - Expression indexes speed up functions like LOWER(email)
-- - Partial indexes limit index size to rows you care about
-- ===========================================================

-- Index for fast lookup by customer
CREATE INDEX idx_orders_customer ON sales.orders (customer_name);

-- Index for department lookups
CREATE INDEX idx_employees_department ON hr.employees (department);

-- Add an email column with uniqueness enforced
ALTER TABLE hr.employees ADD COLUMN email VARCHAR(100) UNIQUE;
CREATE UNIQUE INDEX idx_employees_email_unique ON hr.employees (email);

-- Expression index: speed up case-insensitive email lookups
CREATE INDEX idx_lower_email ON hr.employees ((LOWER(email)));

-- Partial index: efficient index for a small subset (e.g., very high salaries)
CREATE INDEX idx_high_salary ON hr.employees (salary)
WHERE salary > 100000;

-- Examine query plan to ensure index usage (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT * FROM hr.employees WHERE LOWER(email) = 'john@company.com';


/* ===========================================================
   CTEs (WITH clauses)
   - Good for readability, modular queries, and recursion
   - Recursive CTEs are useful for trees/hierarchies (org charts)
   =========================================================== */

-- Seed the sales.orders table with example data
INSERT INTO sales.orders (customer_name, order_date, total_amount) VALUES
('Alice', '2025-10-01', 250.00),
('Bob',   '2025-10-02', 550.00),
('Alice', '2025-10-05', 800.00),
('David', '2025-10-07', 1200.00);

-- Non-recursive CTE: compute per-customer stats then filter
WITH customer_stats AS (
    SELECT customer_name,
           COUNT(order_id)   AS num_orders,
           SUM(total_amount) AS total_spent,
           AVG(total_amount) AS avg_order_value
    FROM sales.orders
    GROUP BY customer_name
)
SELECT *
FROM customer_stats
WHERE total_spent > 500
ORDER BY total_spent DESC;


-- Recursive CTE: build a hierarchy from hr.org_chart
DROP TABLE IF EXISTS hr.org_chart;
CREATE TABLE hr.org_chart (
    emp_id    SERIAL PRIMARY KEY,
    emp_name  VARCHAR(100),
    manager_id INT REFERENCES hr.org_chart(emp_id)  -- self-referential FK
);

INSERT INTO hr.org_chart (emp_name, manager_id) VALUES
('CEO',         NULL),
('CTO',         1),
('Dev Manager', 2),
('Developer',   3),
('Intern',      4);

-- Traverse the tree with a recursive CTE
WITH RECURSIVE hierarchy AS (
    -- Anchor member: root nodes (no manager)
    SELECT emp_id, emp_name, manager_id, 1 AS level
    FROM hr.org_chart
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member: join child rows to the previously found nodes
    SELECT e.emp_id, e.emp_name, e.manager_id, h.level + 1
    FROM hr.org_chart e
    JOIN hierarchy h ON e.manager_id = h.emp_id
)
SELECT emp_id, emp_name, manager_id, level
FROM hierarchy
ORDER BY level;


/* ===========================================================
   JSON / JSONB Handling
   - JSONB is preferable for indexing & performance
   - Use ->, ->> to access keys; @> for containment
   =========================================================== */

DROP TABLE IF EXISTS analytics.products_json;
CREATE TABLE analytics.products_json (
    product_id SERIAL PRIMARY KEY,
    name       TEXT,
    attributes JSONB
);

-- Insert semi-structured product attributes
INSERT INTO analytics.products_json (name, attributes)
VALUES
('Laptop', '{"brand": "Dell", "specs": {"ram": "16GB", "ssd": "512GB"}, "colors": ["black", "silver"]}'),
('Phone',  '{"brand": "Samsung", "specs": {"ram": "8GB", "storage": "128GB"}, "colors": ["blue", "white"]}'),
('Headphones', '{"brand": "Sony", "wireless": true, "battery_life": "30h"}');

-- Extract JSON values
SELECT
    name,
    attributes->>'brand' AS brand,          -- ->> returns text
    attributes->'specs'->>'ram' AS ram     -- -> returns JSON, ->> to text
FROM analytics.products_json;

-- Filter by JSON field
SELECT name, attributes
FROM analytics.products_json
WHERE attributes->>'brand' = 'Dell';

-- Create a GIN index for fast JSONB containment / key/value search
CREATE INDEX idx_products_jsonb ON analytics.products_json USING GIN (attributes);

-- Containment operator sample: find objects with wireless:true
SELECT *
FROM analytics.products_json
WHERE attributes @> '{"wireless": true}';

-- Update nested JSON key (jsonb_set returns modified JSONB)
UPDATE analytics.products_json
SET attributes = jsonb_set(attributes, '{specs,ram}', '"32GB"')
WHERE name = 'Laptop';


/* ===========================================================
   TRIGGERS & AUDITING
   - Triggers can audit inserts/updates/deletes automatically
   - Use trigger functions written in plpgsql for logic
   =========================================================== */

DROP TABLE IF EXISTS analytics.order_audit;
CREATE TABLE analytics.order_audit (
    audit_id     SERIAL PRIMARY KEY,
    order_id     INT,
    customer_name TEXT,
    changed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation    TEXT
);

-- Trigger function inserts an audit row per DML event
CREATE OR REPLACE FUNCTION log_order_changes()
RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO analytics.order_audit (order_id, customer_name, operation)
        VALUES (NEW.order_id, NEW.customer_name, 'INSERT');
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO analytics.order_audit (order_id, customer_name, operation)
        VALUES (NEW.order_id, NEW.customer_name, 'UPDATE');
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO analytics.order_audit (order_id, customer_name, operation)
        VALUES (OLD.order_id, OLD.customer_name, 'DELETE');
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- Attach trigger to sales.orders so every change is logged
DROP TRIGGER IF EXISTS trg_order_audit ON sales.orders;
CREATE TRIGGER trg_order_audit
AFTER INSERT OR UPDATE OR DELETE
ON sales.orders
FOR EACH ROW
EXECUTE FUNCTION log_order_changes();

-- Test the trigger (INSERT / UPDATE / DELETE)
INSERT INTO sales.orders (customer_name, total_amount) VALUES ('Eva', 400.00);
UPDATE sales.orders SET total_amount = 450.00 WHERE customer_name = 'Eva';
DELETE FROM sales.orders WHERE customer_name = 'Eva';

-- View generated audit log
SELECT * FROM analytics.order_audit;


/* ===========================================================
   STORED PROCEDURES (plpgsql)
   - Procedures can be called with CALL and may manage transactions
   - Functions return values and can be used in SQL expressions
   =========================================================== */

-- Procedure to give a percentage raise to employees in a department
CREATE OR REPLACE PROCEDURE hr.raise_salary(dept TEXT, raise_percent NUMERIC)
LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE hr.employees
    SET salary = salary + (salary * raise_percent / 100)
    WHERE department = dept;

    -- RAISE NOTICE prints a helpful message to client logs (for debugging)
    RAISE NOTICE 'Salary updated for department: % by % percent', dept, raise_percent;
END;
$$;

-- Call the procedure (example)
CALL hr.raise_salary('IT', 10);

-- Verify results
SELECT * FROM hr.employees WHERE department = 'IT';


/* ===========================================================
   MATERIALIZED VIEW (caching expensive aggregations)
   - Materialized views store actual rows (faster reads)
   - Must be refreshed to reflect underlying data changes
   =========================================================== */

DROP MATERIALIZED VIEW IF EXISTS analytics.customer_summary;
CREATE MATERIALIZED VIEW analytics.customer_summary AS
SELECT customer_name, SUM(total_amount) AS total_spent
FROM sales.orders
GROUP BY customer_name;

-- Query the cached summary (fast)
SELECT * FROM analytics.customer_summary;

-- When underlying data changes, refresh the materialized view:
REFRESH MATERIALIZED VIEW analytics.customer_summary;


-- ============================================================
-- END OF SCRIPT
-- ============================================================
-- Notes / Best practices (summary within script):
--  * Run in a dev database first. Use DROP IF EXISTS to allow reruns.
--  * Use transactions (BEGIN/COMMIT/ROLLBACK) around multi-step operations.
--  * Add indexes selectively; use EXPLAIN ANALYZE to confirm they help.
--  * Prefer JSONB over JSON when you need indexing and efficient queries.
--  * Keep business logic in a small number of well-tested stored procedures,
--    but prefer application-level logic for complex workflows unless latency
--    or atomicity requires database-side operations.
--  * Use proper secrets management and do NOT store plain passwords in scripts.
-- ============================================================