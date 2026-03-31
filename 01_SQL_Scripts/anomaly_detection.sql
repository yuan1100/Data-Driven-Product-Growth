-- ============================================================================
-- Script Name: anomaly_detection.sql
-- Description: Automated anomaly detection for interactive courseware.
--              Calculates Secondary Error Rate and Frequent Error Rate 
--              to proactively flag product interaction defects.
-- Note:        Date ranges are hardcoded for portfolio demonstration purposes. 
--              In production, replace with dynamic macros (e.g., CURRENT_DATE - 7).
-- Author:      Data Analytics Manager
-- ============================================================================

WITH 
-- 1. Identify valid first-lesson classroom sessions (Exclude review data pollution)
First_Lesson_Sessions AS (
    SELECT student_id, lesson_code
    FROM (
        SELECT user_id AS student_id, 
               lesson_code,
               ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY start_time ASC) AS rn
        FROM app_log_db.fact_classroom_sessions 
        WHERE status = 1 
          AND start_time IS NOT NULL 
          AND data_dt BETWEEN '2023-10-01' AND '2023-10-21'
    ) a WHERE rn = 1
),

-- 2. Parse raw JSON event streams for branch triggers
Parsed_Branch_Events AS (
    SELECT uid,
           lesson_code,
           get_json_object(payload, '$.interaction_code') AS interaction_code,
           get_json_object(payload, '$.branch_type') AS branch_type,
           get_json_object(payload, '$.trace_id') AS trace_id
    FROM app_log_db.fact_event_streams
    WHERE data_dt BETWEEN '2023-10-01' AND '2023-10-21'
      AND event = 'trigger-branch'
      AND role_type = 'student'
),

-- 3. Map events to valid sessions and calculate base metrics
Interaction_Metrics AS (
    SELECT 
        e.lesson_code,
        e.interaction_code,
        COUNT(DISTINCT e.uid) AS total_interaction_users,
        
        -- Count unique users hitting specific anomaly branches
        COUNT(DISTINCT CASE WHEN e.branch_type = 'secondary_error' THEN e.uid END) AS secondary_error_users,
        COUNT(DISTINCT CASE WHEN e.branch_type = 'frequent_error' THEN e.uid END) AS frequent_error_users,
        COUNT(DISTINCT CASE WHEN e.branch_type = 'correct' THEN e.uid END) AS correct_users
        
    FROM Parsed_Branch_Events e
    INNER JOIN First_Lesson_Sessions f 
        ON e.uid = f.student_id AND e.lesson_code = f.lesson_code
    GROUP BY e.lesson_code, e.interaction_code
)

-- 4. Calculate anomaly rates and trigger automated alerts based on business thresholds
SELECT 
    lesson_code,
    interaction_code,
    total_interaction_users,
    
    -- Secondary Error Metrics (Fixed integer division using CAST)
    secondary_error_users,
    ROUND(CAST(secondary_error_users AS DOUBLE) / total_interaction_users, 4) AS secondary_error_rate,
    
    -- Frequent Error Metrics (Fixed integer division using CAST)
    frequent_error_users,
    ROUND(CAST(frequent_error_users AS DOUBLE) / total_interaction_users, 4) AS frequent_error_rate,
    
    -- Automated Alert Flagging (Business Rules Engine)
    CASE 
        WHEN (CAST(frequent_error_users AS DOUBLE) / total_interaction_users) >= 0.30 THEN 'ALERT: High Frequent Misoperation (>=30%)'
        WHEN (CAST(secondary_error_users AS DOUBLE) / total_interaction_users) >= 0.15 THEN 'WARNING: High Secondary Error (>=15%)'
        ELSE 'Normal' 
    END AS anomaly_alert_status
    
FROM Interaction_Metrics
WHERE total_interaction_users > 30 -- Statistical significance filter (Ensure sufficient sample size)
ORDER BY frequent_error_rate DESC, secondary_error_rate DESC;
