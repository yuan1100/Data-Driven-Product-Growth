-- ============================================================================
-- Script Name: micro_funnel_bpse.sql
-- Description: B-P-S-E (Block-Part-Scene-Element) 4-Level Funnel Analysis.
--              Parses unstructured JSON event tracking logs to build a highly 
--              granular user behavior trajectory tree and locate drop-offs.
-- Note:        Date ranges are hardcoded for portfolio demonstration purposes. 
--              In production, replace with dynamic macros (e.g., CURRENT_DATE - 7).
-- Author:      Data Analytics Manager
-- ============================================================================

WITH 
-- 1. Identify valid first-lesson classroom sessions (Exclude review data pollution)
First_Lesson_Users AS (
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

-- 2. Parse raw JSON event streams for ALL 4 B-P-S-E interaction levels at once
Parsed_Events AS (
    SELECT uid, 
           lesson_code,
           event, 
           get_json_object(payload, '$.interaction_code') AS interaction_code, 
           get_json_object(payload, '$.trace_id') AS trace_id
    FROM app_log_db.fact_event_streams 
    WHERE data_dt BETWEEN '2023-10-01' AND '2023-10-21' 
      AND role_type = 'student' 
)

-- 3. Build the B-P-S-E Granular Funnel using Conditional Aggregation
SELECT 
    p.lesson_code,
    p.interaction_code,
    COUNT(DISTINCT f.student_id) AS total_class_users,
    
    -- Level 1: Block (Module Entry & Exit)
    COUNT(DISTINCT CASE WHEN p.event = 'enter-block' THEN p.uid END) AS enter_block_users,
    COUNT(DISTINCT CASE WHEN p.event = 'leave-block' THEN p.uid END) AS leave_block_users,
    
    -- Level 2: Part (Task Entry & Exit)
    COUNT(DISTINCT CASE WHEN p.event = 'enter-part' THEN p.uid END) AS enter_part_users,
    COUNT(DISTINCT CASE WHEN p.event = 'leave-part' THEN p.uid END) AS leave_part_users,
    
    -- Level 3: Scene (Specific Scene Entry & Exit)
    COUNT(DISTINCT CASE WHEN p.event = 'enter-scene' THEN p.uid END) AS enter_scene_users,
    COUNT(DISTINCT CASE WHEN p.event = 'leave-scene' THEN p.uid END) AS leave_scene_users,
    
    -- Level 4: Element (Micro-Interaction Entry & Exit)
    COUNT(DISTINCT CASE WHEN p.event = 'enter-element' THEN p.uid END) AS enter_element_users,
    COUNT(DISTINCT CASE WHEN p.event = 'leave-element' THEN p.uid END) AS leave_element_users,
    
    -- Core Drop-off Metric: Element Completion Rate
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN p.event = 'leave-element' THEN p.uid END) AS DOUBLE) 
        / NULLIF(COUNT(DISTINCT CASE WHEN p.event = 'enter-element' THEN p.uid END), 0), 
    4) AS element_completion_rate

FROM Parsed_Events p
INNER JOIN First_Lesson_Users f 
    ON p.uid = f.student_id AND p.lesson_code = f.lesson_code
GROUP BY p.lesson_code, p.interaction_code
ORDER BY element_completion_rate ASC;
