-- Drop existing tables (if rerunning)
DROP TABLE IF EXISTS Data_Sets;
DROP TABLE IF EXISTS Model_Training;
DROP TABLE IF EXISTS Tasks;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Projects;

-- 1. CREATE TABLES

CREATE TABLE Projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12, 2),
    client_name VARCHAR(100)
);

CREATE TABLE Tasks (
    task_id INT PRIMARY KEY,
    project_id INT,
    task_name VARCHAR(100),
    assigned_to INT,
    due_date DATE,
    is_completed BOOLEAN,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

CREATE TABLE Teams (
    team_member_id INT PRIMARY KEY,
    member_name VARCHAR(100),
    role VARCHAR(50),
    email VARCHAR(100),
    joined_on DATE
);

-- Optional Tables
CREATE TABLE Model_Training (
    training_id INT PRIMARY KEY,
    project_id INT,
    model_name VARCHAR(100),
    accuracy DECIMAL(5,2),
    training_date DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

CREATE TABLE Data_Sets (
    dataset_id INT PRIMARY KEY,
    project_id INT,
    dataset_name VARCHAR(100),
    size_gb DECIMAL(5,2),
    last_updated DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

-- 2. INSERT SAMPLE DATA

INSERT INTO Projects VALUES 
(1, 'AI Chatbot', '2024-01-01', '2024-06-30', 500000, 'ABC Corp'),
(2, 'E-commerce Platform', '2024-02-15', '2024-10-01', 750000, 'ShopEasy'),
(3, 'Smart City Dashboard', '2024-03-01', '2024-09-30', 900000, 'GovTech'),
(4, 'IoT Home Automation', '2024-04-01', '2024-12-31', 600000, 'HomePlus'),
(5, 'Healthcare Predictive Model', '2024-05-10', '2024-11-10', 950000, 'Health360');

INSERT INTO Teams VALUES 
(101, 'Alice', 'Team Lead', 'alice@example.com', '2023-01-01'),
(102, 'Bob', 'Developer', 'bob@example.com', '2023-02-01'),
(103, 'Charlie', 'Analyst', 'charlie@example.com', '2023-03-01'),
(104, 'Diana', 'Team Lead', 'diana@example.com', '2023-01-15'),
(105, 'Eve', 'Tester', 'eve@example.com', '2023-04-01');

INSERT INTO Tasks VALUES
(1, 1, 'Build NLP Engine', 101, '2025-08-10', TRUE),
(2, 1, 'Data Collection', 102, '2025-08-05', FALSE),
(3, 2, 'Frontend UI', 103, '2025-08-15', TRUE),
(4, 3, 'Sensor Integration', 104, '2025-08-07', FALSE),
(5, 1, 'Deploy Chatbot', 101, '2025-08-09', TRUE);

INSERT INTO Model_Training VALUES
(1, 1, 'GPT-3 Variant', 89.5, '2025-07-20'),
(2, 1, 'Custom LSTM', 91.0, '2025-07-25'),
(3, 3, 'CNN Model', 88.0, '2025-07-10');

INSERT INTO Data_Sets VALUES
(1, 1, 'Conversation Logs', 12.5, '2025-07-20'),
(2, 2, 'Customer DB', 8.0, '2025-06-10'),
(3, 3, 'Traffic Sensor Data', 15.2, '2025-07-15');

-- Q1: Projects with total and completed tasks using CTE
WITH task_counts AS (
  SELECT project_id,
         COUNT(*) AS total_tasks,
         COUNT(CASE WHEN is_completed THEN 1 END) AS completed_tasks
  FROM Tasks
  GROUP BY project_id
)
SELECT p.project_name, tc.total_tasks, tc.completed_tasks
FROM Projects p
JOIN task_counts tc ON p.project_id = tc.project_id;

-- Q2: Top 2 team members with most tasks
SELECT * FROM (
  SELECT t.assigned_to, tm.member_name, COUNT(*) AS task_count,
         ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM Tasks t
  JOIN Teams tm ON t.assigned_to = tm.team_member_id
  GROUP BY t.assigned_to, tm.member_name
) ranked
WHERE rnk <= 2;

-- Q3: Tasks due earlier than project avg due_date
SELECT t1.*
FROM Tasks t1
WHERE t1.due_date < (
  SELECT AVG(t2.due_date)
  FROM Tasks t2
  WHERE t2.project_id = t1.project_id
);

-- Q4: Project(s) with maximum budget
SELECT *
FROM Projects
WHERE budget = (SELECT MAX(budget) FROM Projects);

-- Q5: % of completed tasks per project
SELECT p.project_name,
       ROUND(
         100.0 * COUNT(CASE WHEN t.is_completed THEN 1 END) / COUNT(*), 2
       ) AS completion_percentage
FROM Projects p
JOIN Tasks t ON p.project_id = t.project_id
GROUP BY p.project_name;

-- Q6: Window function to count tasks per assignee
SELECT t.task_name, tm.member_name AS assigned_to,
       COUNT(*) OVER (PARTITION BY t.assigned_to) AS tasks_per_member
FROM Tasks t
JOIN Teams tm ON t.assigned_to = tm.team_member_id
ORDER BY tm.member_name;

-- Q7: Incomplete tasks assigned to team leads due in next 15 days
SELECT t.*
FROM Tasks t
JOIN Teams tm ON t.assigned_to = tm.team_member_id
WHERE tm.role = 'Team Lead'
  AND t.is_completed = FALSE
  AND t.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '15' DAY;

-- Q8: Projects with no tasks
SELECT *
FROM Projects p
WHERE NOT EXISTS (
  SELECT 1 FROM Tasks t WHERE t.project_id = p.project_id
);

-- Q9: Project with best AI model (highest accuracy)
SELECT p.project_name, mt.model_name, mt.accuracy
FROM Model_Training mt
JOIN Projects p ON mt.project_id = p.project_id
WHERE (mt.project_id, mt.accuracy) IN (
  SELECT project_id, MAX(accuracy)
  FROM Model_Training
  GROUP BY project_id
);

-- Q10: Projects with large datasets updated in last 30 days
SELECT DISTINCT p.project_name, d.dataset_name, d.size_gb
FROM Data_Sets d
JOIN Projects p ON d.project_id = p.project_id
WHERE d.size_gb > 10
  AND d.last_updated >= CURRENT_DATE - INTERVAL '30' DAY;
