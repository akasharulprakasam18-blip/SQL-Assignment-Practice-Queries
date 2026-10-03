Create database SQL_assignmentdb; 
Use SQL_assignmentdb

-- Q1 Department Salary Analysis

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    joining_date DATE
);

INSERT INTO employees VALUES
(101, 'Akash', 'IT', 60000.00, '2023-01-15'),
(102, 'Arthi', 'IT', 75000.00, '2022-06-10'),
(103, 'Karthik', 'IT', 50000.00, '2024-02-20'),
(104, 'Ajith', 'IT', 90000.00, '2021-08-05'),
(105, 'Priya', 'HR', 55000.00, '2023-03-12'),
(106, 'Meena', 'HR', 65000.00, '2022-11-18'),
(107, 'Ravi', 'HR', 48000.00, '2024-01-10'),
(108, 'Suresh', 'Finance', 80000.00, '2021-05-25');

select * from employees

SELECT employee_name, department, salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg,
       salary - AVG(salary) OVER (PARTITION BY department) AS diff
FROM employees;



-- Q2 Top 3 Employees in Each Department


SELECT employee_name, department, salary, dept_rank
FROM (
    SELECT 
        employee_name,
        department,
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
    FROM employees
) AS ranked_employees
WHERE dept_rank <= 3;


-- Q3 Second Highest Salary by Department

SELECT department, salary
FROM (
    SELECT department, salary,
           DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM employees
) t WHERE rnk = 2;



-- Q4 Employees Earning More Than Department Average

WITH dept_avg AS (
    SELECT department, AVG(salary) AS dept_avg FROM employees GROUP BY department
)
SELECT e.employee_name, e.department, e.salary, d.dept_avg
FROM employees e JOIN dept_avg d ON e.department = d.department
WHERE e.salary > d.dept_avg;

-- Q5 Latest Employee Record

CREATE TABLE employees_history (
    employee_id INT,
    employee_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    updated_at DATETIME
);

INSERT INTO employees_history VALUES
(101, 'Akash', 'IT', 60000.00, '2023-01-15 10:00:00'),
(101, 'Akash', 'IT', 65000.00, '2024-01-20 09:30:00'),
(101, 'Akash', 'IT', 70000.00, '2025-03-05 14:15:00'),
(102, 'Arthi', 'IT', 75000.00, '2022-06-10 11:00:00'),
(102, 'Arthi', 'IT', 80000.00, '2024-07-12 16:45:00');

select * from employees_history

SELECT employee_id, employee_name, department, salary, updated_at FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY updated_at DESC) AS rn
    FROM employees_history
) t WHERE rn = 1;

-- Q6 Employee Salary Ranking

SELECT employee_name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dense_rnk,
       ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num
FROM employees;

-- Q7 Month-over-Month Sales Analysis

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    customer_id INT,
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO sales VALUES
(1, 201, '2026-01-10', 5000.00),
(2, 201, '2026-01-11', 7000.00),
(3, 202, '2026-02-05', 8000.00),
(4, 202, '2026-03-07', 6000.00),
(5, 203, '2026-03-15', 10000.00),
(6, 203, '2026-04-20', 12000.00);

select * from sales
WITH monthly_sales AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month,
           SUM(amount) AS total_sales
    FROM sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
)
SELECT month,
       total_sales,
       LAG(total_sales) OVER (ORDER BY month) AS prev_sales,
       total_sales - LAG(total_sales) OVER (ORDER BY month) AS diff
FROM monthly_sales;

-- Q8 – Customer Purchase Analysis
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO orders (order_id, customer_id, order_date, amount)
VALUES
(1, 201, '2026-01-10', 5000.00),
(2, 201, '2026-01-11', 7000.00),
(3, 202, '2026-02-05', 8000.00),
(4, 202, '2026-03-07', 6000.00),
(5, 203, '2026-03-15', 10000.00),
(6, 203, '2026-04-20', 12000.00),
(7, 204, '2026-05-01', 4000.00);

SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    SUM(amount) AS total_amount_spent,
    AVG(amount) AS avg_order_value
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1;

-- Q9 – Customers With No Orders
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50)
);
INSERT INTO customers (customer_id, customer_name)
VALUES
(201, 'Ramesh'),
(202, 'Geetha'),
(203, 'Vikram'),
(204, 'Divya'),
(205, 'Naveen');

-- Part A: LEFT JOIN
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Part B: Subquery
SELECT customer_id, customer_name
FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders);

-- Question 10 – Consecutive Customer Purchases

SELECT customer_id, order_date, prev_date
FROM (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_date
    FROM orders
) t
WHERE DATEDIFF(order_date, prev_date) = 1;

-- Question 11 – Customer First and Last Purchase

SELECT 
    customer_id,
    FIRST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_purchase_date,
    LAST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_purchase_date,
    FIRST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_purchase_amount,
    LAST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_purchase_amount
FROM orders;

-- Question 12 – Data Cleaning Using Conditional Functions

CREATE TABLE customers_data (
    customer_id INT,
    customer_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    salary DECIMAL(10,2),
    created_at DATETIME
);

INSERT INTO customers_data VALUES
(301, ' Ramesh ', 'ramesh@example.com', '9876543210', 50000.00, '2026-01-01 10:00:00'),
(302, NULL, 'geetha@example.com', '9876543211', NULL, '2026-01-02 11:00:00'),
(303, 'Vikram', 'vikram@example.com', '9876543212', 0, '2026-01-03 12:00:00'),
(304, 'Divya', 'divya@example.com', '9876543213', 60000.00, '2026-01-04 13:00:00'),
(305, 'Naveen', 'ramesh@example.com', '9876543214', 70000.00, '2026-01-05 14:00:00');

SELECT 
    customer_id,
    COALESCE(TRIM(UPPER(customer_name)), 'UNKNOWN') AS cleaned_name,
    email,
    phone,
    NULLIF(COALESCE(salary, 0), 0) AS cleaned_salary,
    CASE 
        WHEN salary IS NULL THEN 'No Salary'
        WHEN salary = 0 THEN 'Invalid Salary'
        ELSE 'Valid Salary'
    END AS status
FROM customers_data;


-- Question 13 – Duplicate Customer Detection

SELECT 
    customer_id,
    COALESCE(TRIM(UPPER(customer_name)), 'UNKNOWN') AS cleaned_name,
    email,
    phone,
    NULLIF(COALESCE(salary, 0), 0) AS cleaned_salary,
    CASE 
        WHEN salary IS NULL THEN 'No Salary'
        WHEN salary = 0 THEN 'Invalid Salary'
        ELSE 'Valid Salary'
    END AS status
FROM customers_data;

-- Question 13 – Duplicate Customer Detection

-- Step 1: Find duplicates
SELECT email, COUNT(*) AS duplicate_count
FROM customers_data
GROUP BY email
HAVING COUNT(*) > 1;

-- Step 2: Latest record per duplicate
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) AS rn
    FROM customers_data
) t
WHERE rn = 1;

-- Question 14 – Employee Hierarchy Using Recursive CTE

CREATE TABLE employee_hierarchy (
    employee_id INT,
    employee_name VARCHAR(50),
    manager_id INT
);

INSERT INTO employee_hierarchy VALUES
(1, 'CEO', NULL),
(2, 'Manager1', 1),
(3, 'Manager2', 1),
(4, 'Employee1', 2),
(5, 'Employee2', 2),
(6, 'Employee3', 3);

WITH RECURSIVE hierarchy AS (
    SELECT employee_id, employee_name, manager_id, 0 AS level
    FROM employee_hierarchy
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.employee_name, e.manager_id, h.level + 1
    FROM employee_hierarchy e
    JOIN hierarchy h ON e.manager_id = h.employee_id
)
SELECT * FROM hierarchy;

-- Question 15 – Multi-CTE Sales Analysis

WITH cte1 AS (
    SELECT customer_id, SUM(amount) AS total_sales
    FROM orders
    GROUP BY customer_id
),
cte2 AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM cte1
),
cte3 AS (
    SELECT c.customer_id, c.customer_name, c1.total_sales, c2.avg_sales
    FROM customers c
    JOIN cte1 c1 ON c.customer_id = c1.customer_id
    CROSS JOIN cte2 c2
    WHERE c1.total_sales > c2.avg_sales
)
SELECT * FROM cte3;

-- Question 16 – Top 3 Product Categories

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category_id INT,
    product_name VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE orders_products (
    order_id INT,
    product_id INT,
    quantity INT
);

INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Clothing'),
(3, 'Books');

INSERT INTO products VALUES
(101, 1, 'Laptop', 60000.00),
(102, 1, 'Smartphone', 30000.00),
(103, 2, 'T-Shirt', 1000.00),
(104, 2, 'Jeans', 2000.00),
(105, 3, 'Novel', 500.00);

INSERT INTO orders_products VALUES
(1, 101, 1),
(2, 102, 2),
(3, 103, 5),
(4, 104, 3),
(5, 105, 10);


SELECT
c.category_name,
COUNT(DISTINCT op.order_id) AS total_orders,
SUM(op.quantity) AS total_quantity,
SUM(op.quantity * p.price) AS total_revenue
FROM orders_products op
JOIN products p
ON op.product_id = p.product_id
JOIN categories c
ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_revenue DESC
LIMIT 3;


-- Question 17 –Set Operators: Customer Comparison

-- Customers for 2025
CREATE TABLE customers_2025 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50)
);

-- Customers for 2026
CREATE TABLE customers_2026 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50)
);
INSERT INTO customers_2025 VALUES
(201, 'Ramesh'),
(202, 'Geetha'),
(203, 'Vikram'),
(204, 'Divya');

INSERT INTO customers_2026 VALUES
(202, 'Geetha'),
(203, 'Vikram'),
(205, 'Naveen'),
(206, 'Meena');

-- 1. Customers present in both 2025 and 2026
SELECT customer_id, customer_name
FROM customers_2025
INTERSECT
SELECT customer_id, customer_name
FROM customers_2026;

-- 2. Customers present only in 2025
SELECT customer_id, customer_name
FROM customers_2025
EXCEPT
SELECT customer_id, customer_name
FROM customers_2026;

-- 3. Customers present only in 2026
SELECT customer_id, customer_name
FROM customers_2026
EXCEPT
SELECT customer_id, customer_name
FROM customers_2025;

-- 4. All unique customers from both years
SELECT customer_id, customer_name
FROM customers_2025
UNION
SELECT customer_id, customer_name
FROM customers_2026;

-- UNION vs UNION ALL
-- UNION removes duplicates
SELECT customer_id, customer_name
FROM customers_2025
UNION
SELECT customer_id, customer_name
FROM customers_2026;

-- UNION ALL keeps duplicates
SELECT customer_id, customer_name
FROM customers_2025
UNION ALL
SELECT customer_id, customer_name
FROM customers_2026;


-- Question 18 – Stored Procedure: Employee Search


DELIMITER $$

CREATE PROCEDURE GetEmployeesByDepartment (IN DepartmentName VARCHAR(50))
BEGIN
    SELECT 
        employee_id,
        employee_name,
        department,
        salary,
        joining_date
    FROM employees
    WHERE department = DepartmentName;
END$$

DELIMITER ;


