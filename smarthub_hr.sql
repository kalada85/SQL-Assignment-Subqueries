Scripts
CREATE TABLE employees (
emp_id SERIAL PRIMARY KEY,
full_name VARCHAR(80) NOT NULL,
department VARCHAR(40) NOT NULL,
role VARCHAR(40) NOT NULL,
city VARCHAR(40) NOT NULL,
salary NUMERIC(12,2) NOT NULL,
bonus NUMERIC(12,2), -- nullable: not everyone earns a bonus
hire_date DATE NOT NULL,
manager_id INTEGER REFERENCES employees(emp_id) -- self reference; NULL = top manager
);
INSERT INTO employees (full_name, department, role, city, salary, bonus, hire_date, manager_id) VALUES
('Adaeze Okafor', 'Management', 'CEO', 'Lagos', 1500000, 500000, '2018-01-10', NULL),
('Emeka Nwosu', 'Engineering','Engineering Lead', 'Port Harcourt', 950000, 200000, '2019-03-15', 1),
('Fatima Bello', 'Sales', 'Sales Lead', 'Abuja', 900000, 250000, '2019-06-01', 1),
('Ngozi Okeke', 'Marketing', 'Marketing Lead', 'Lagos', 870000, 180000, '2020-02-20', 1),
('Chinedu Eze', 'Engineering','Backend Dev', 'Port Harcourt', 620000, 80000, '2021-04-12', 2),
('Blessing Johnson', 'Engineering','Frontend Dev', 'Port Harcourt', 590000, NULL, '2021-07-30', 2),
('Yusuf Ibrahim', 'Engineering','Backend Dev', 'Kano', 640000, 90000, '2020-11-05', 2),
('Tunde Adeyemi', 'Sales', 'Sales Rep', 'Abuja', 420000, 60000, '2022-01-18', 3),
('Halima Suleiman', 'Sales', 'Sales Rep', 'Abuja', 410000, NULL, '2022-03-22', 3),
('Kelechi Amadi', 'Sales', 'Sales Rep', 'Port Harcourt', 450000, 75000, '2021-09-09', 3),
('Funmilayo Adebayo','Marketing', 'Content Strategist','Lagos', 480000, 40000, '2022-05-14', 4),
('Victor Obi', 'Marketing', 'SEO Specialist', 'Enugu', 460000, NULL, '2023-02-01', 4),
('Grace Effiong', 'Engineering','QA Engineer', 'Port Harcourt', 520000, 50000, '2023-06-19', 2),
('Sadiq Mohammed', 'Sales', 'Sales Rep', 'Kano', 400000, 55000, '2023-08-25', 3),
('Aisha Garba', 'Marketing', 'Designer', 'Abuja', 470000, NULL, '2024-01-30', 4),
('Daniel Okonkwo', 'Engineering','Intern', 'Enugu', 250000, NULL, '2024-07-15', 2);

-- Confirm it loaded:

SELECT * FROM employees;

1. Employees earning more than the company average

SELECT *
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
);

2. Employees in the same department as Chinedu Eze

SELECT *
FROM employees
WHERE department = (
    SELECT department
    FROM employees
    WHERE full_name = 'Chinedu Eze'
);
Chinedu is in Engineering, so this returns all Engineering employees.


3. Employee(s) with the highest salary

SELECT *
FROM employees
WHERE salary = (
    SELECT MAX(salary)
    FROM employees
);
This is better than ORDER BY ... LIMIT 1 because it would return all employees if there were a tie.


4. Employee(s) with the lowest salary

SELECT *
FROM employees
WHERE salary = (
    SELECT MIN(salary)
    FROM employees
);

5. Employees earning below the company average

SELECT *
FROM employees
WHERE salary < (
    SELECT AVG(salary)
    FROM employees
);

6. Employees earning more than the average salary in their own department
This is a correlated subquery because the inner query refers to the employee in the outer query.

SELECT *
FROM employees e
WHERE salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department = e.department
);
The important part is:
WHERE e2.department = e.department
It tells PostgreSQL to calculate the average for that employee's department.


7. Employees earning more than Grace Effiong

SELECT *
FROM employees
WHERE salary > (
    SELECT salary
    FROM employees
    WHERE full_name = 'Grace Effiong'
);

Grace Effiong earns ₦520,000, so everyone above that salary is returned.

8. Employees earning more than every Sales employee
Use ALL:

SELECT *
FROM employees
WHERE salary > ALL (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

This means the employee's salary must be greater than every salary returned by the Sales subquery.

9. Employees earning more than at least one Engineering employee
Use ANY:

SELECT *
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Engineering'
);

This means the salary only needs to be greater than at least one Engineering salary.

10. Employees who earn more than their own manager
Another correlated subquery:

SELECT *
FROM employees e
WHERE salary > (
    SELECT m.salary
    FROM employees m
    WHERE m.emp_id = e.manager_id
);

The inner query finds the employee's manager and compares the two salaries.

11. Employees who do NOT manage anyone
We can use NOT EXISTS:

SELECT *
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e2
    WHERE e2.manager_id = e.emp_id
);

The subquery checks whether anyone has that employee's emp_id as their manager_id.

12. Employees who manage at least one other employee
The opposite of Question 11:

SELECT *
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM employees e2
    WHERE e2.manager_id = e.emp_id
);

13. Employees hired before Kelechi Amadi

SELECT *
FROM employees
WHERE hire_date < (
    SELECT hire_date
    FROM employees
    WHERE full_name = 'Kelechi Amadi'
);

Kelechi Amadi was hired on 2021-09-09.

14. Employees whose salary equals the highest salary in their department

SELECT *
FROM employees e
WHERE salary = (
    SELECT MAX(e2.salary)
    FROM employees e2
    WHERE e2.department = e.department
);

Again, this is a correlated subquery.
It finds the maximum salary for the employee's department and then checks whether that employee earns it.

15. Employees earning more than the average bonus of employees who receive a bonus
The question specifically says employees who actually receive a bonus, so we exclude NULL.

SELECT *
FROM employees
WHERE bonus > (
    SELECT AVG(bonus)
    FROM employees
    WHERE bonus IS NOT NULL
);

Important: AVG() already ignores NULL, but including WHERE bonus IS NOT NULL makes the intention clear.

16. Department(s) whose average salary is above the company-wide average
One employee per qualifying department is acceptable.

SELECT *
FROM employees e
WHERE e.department IN (
    SELECT department
    FROM employees
    GROUP BY department
    HAVING AVG(salary) > (
        SELECT AVG(salary)
        FROM employees
    )
);

This returns all employees belonging to qualifying departments.
If your lecturer literally wants only one employee per department, we can use a different query.

17. Employees earning more than the average Engineering salary

SELECT *
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department = 'Engineering'
);

18. Employees whose salary is within ₦200,000 of the top earner
The highest salary is obtained with MAX():

SELECT *
FROM employees
WHERE salary >= (
    SELECT MAX(salary) - 200000
    FROM employees
);

Since the highest salary is ₦1,500,000, the threshold is:
₦1,500,000 − ₦200,000 = ₦1,300,000
So this will return employees earning at least ₦1.3 million.

19. Derived table — Engineering employees earning above ₦500,000
This question specifically requires a subquery in the FROM clause, so don't change this to a normal WHERE subquery.

SELECT *
FROM (
    SELECT *
    FROM employees
    WHERE department = 'Engineering'
      AND salary > 500000
) AS engineering_staff;

The important concept here is:
FROM (
    SELECT ...
) AS engineering_staff

The subquery creates a temporary result set, also called a derived table.

20. Employee with the second-highest salary
A good subquery solution is:

SELECT *
FROM employees
WHERE salary = (
    SELECT MAX(salary)
    FROM employees
    WHERE salary < (
        SELECT MAX(salary)
        FROM employees
    )
);


