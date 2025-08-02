-- ---------------------------------------------
-- Create Tables
-- ---------------------------------------------

-- Table: Projects
CREATE TABLE Projects (
    project_id INTEGER PRIMARY KEY,
    project_name TEXT NOT NULL,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10, 2)
);

-- Table: Tasks
CREATE TABLE Tasks (
    task_id INTEGER PRIMARY KEY,
    project_id INTEGER,
    task_name TEXT,
    assigned_to TEXT,
    due_date DATE,
    status TEXT,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

-- Table: Teams
CREATE TABLE Teams (
    member_id INTEGER PRIMARY KEY,
    member_name TEXT,
    role TEXT,
    email TEXT,
    phone TEXT
);

-- Table: Model_Training
CREATE TABLE Model_Training (
    training_id INTEGER PRIMARY KEY,
    project_id INTEGER,
    model_name TEXT,
    accuracy DECIMAL(5,2),
    training_date DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

-- Table: Data_Sets
CREATE TABLE Data_Sets (
    dataset_id INTEGER PRIMARY KEY,
    project_id INTEGER,
    dataset_name TEXT,
    size_gb DECIMAL(5,2),
    last_updated DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

-- ---------------------------------------------
-- Insert Sample Data
-- ---------------------------------------------

-- Projects
INSERT INTO Projects VALUES
(1, 'AI Chatbot', '2024-01-10', '2024-06-30', 150000),
(2, 'Fraud Detection', '2024-03-01', '2024-09-01', 200000),
(3, 'Recommendation System', '2024-02-15', '2024-07-15', 180000),
(4, 'Healthcare Analysis', '2024-04-10', '2024-08-30', 170000),
(5, 'Customer Insights', '2024-05-01', '2024-10-01', 160000);

-- Tasks
INSERT INTO Tasks VALUES
(1, 1, 'Design architecture', 'Alice', '2024-04-01', 'completed'),
(2, 1, 'Build backend', 'Bob', '2024-05-10', 'pending'),
(3, 2, 'Data collection', 'Alice', '2024-06-01', 'completed'),
(4, 3, 'Model training', 'Charlie', '2024-07-01', 'pending'),
(5, 3, 'Evaluation', 'Bob', '2024-06-25', 'completed');

-- Teams
INSERT INTO Teams VALUES
(1, 'Alice', 'Team Lead', 'alice@example.com', '1234567890'),
(2, 'Bob', 'Data Scientist', 'bob@example.com', '2345678901'),
(3, 'Charlie', 'Team Lead', 'charlie@example.com', '3456789012');

-- Model_Training
INSERT INTO Model_Training VALUES
(1, 1, 'GPT-X', 89.5, '2024-04-15'),
(2, 2, 'FraudNet', 92.3, '2024-06-20'),
(3, 2, 'SecureAI', 94.0, '2024-07-10'),
(4, 3, 'RecSys', 88.0, '2024-06-15');

-- Data_Sets
INSERT INTO Data_Sets VALUES
(1, 1, 'chat_logs', 12.5, DATE('now')),
(2, 2, 'transactions', 15.0, DATE('now', '-10 days')),
(3, 3, 'user_behavior', 8.0, DATE('now', '-40 days')),
(4, 4, 'patient_data', 20.0, DATE('now', '-5 days'));

-- ---------------------------------------------
-- Queries
-- ---------------------------------------------

-- 1. CTE for total and completed tasks per project
WITH TaskCounts AS (
    SELECT project_id,
           COUNT(*) AS total_tasks,
           SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks
    FROM Tasks
    GROUP BY project_id
)
SELECT p.project_name, t.total_tasks, t.completed_tasks
FROM Projects p
JOIN TaskCounts t ON p.project_id = t.project_id;

-- 2. Top 2 team members by number of tasks assigned
WITH TaskRanks AS (
    SELECT assigned_to,
           COUNT(*) AS task_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM Tasks
    GROUP BY assigned_to
)
SELECT assigned_to, task_count
FROM TaskRanks
WHERE rnk <= 2;

-- 3. Tasks due earlier than average due date in same project
SELECT *
FROM Tasks t1
WHERE due_date < (
    SELECT AVG(julianday(due_date))
    FROM Tasks t2
    WHERE t2.project_id = t1.project_id
);

-- 4. Project(s) with max budget
SELECT *
FROM Projects
WHERE budget = (SELECT MAX(budget) FROM Projects);

-- 5. Percentage of completed tasks per project
SELECT project_id,
       ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS completion_percentage
FROM Tasks
GROUP BY project_id;

-- 6. Task, assigned_to, task count per person (window function)
SELECT task_name, assigned_to,
       COUNT(*) OVER (PARTITION BY assigned_to) AS tasks_per_person
FROM Tasks
ORDER BY assigned_to;

-- 7. Incomplete tasks assigned to team leads due in next 15 days
SELECT t.*
FROM Tasks t
JOIN Teams m ON t.assigned_to = m.member_name
WHERE m.role = 'Team Lead'
  AND t.status != 'completed'
  AND due_date <= DATE('now', '+15 days');

-- 8. Projects with no tasks assigned
SELECT *
FROM Projects
WHERE project_id NOT IN (
    SELECT DISTINCT project_id FROM Tasks
);

-- 9. Best model (highest accuracy) per project
SELECT project_id, model_name, accuracy
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY project_id ORDER BY accuracy DESC) AS rnk
    FROM Model_Training
)
WHERE rnk = 1;

-- 10. Projects with datasets > 10GB updated in last 30 days
SELECT DISTINCT p.*
FROM Projects p
JOIN Data_Sets d ON p.project_id = d.project_id
WHERE d.size_gb > 10
  AND d.last_updated >= DATE('now', '-30 days');
