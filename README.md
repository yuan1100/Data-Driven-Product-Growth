# Data-Driven Product Optimization & User Growth Practice

**Project Role:** Data Analytics Manager / Project Lead  
**Domain:** EdTech / Interactive Kids Online Courses  
**Core Tech Stack:** Advanced SQL (Hive/Presto), JSON Parsing, Funnel Analytics, A/B Testing, Project Management, Team Leadership  

---

## Executive Summary & Business Value

The core business objective of this project was to optimize product content, enhance user experience, and improve retention. By leading a 2-person analytics team and shifting our operational model from reactive troubleshooting to proactive data-driven intervention, we successfully reduced user churn and drove measurable conversion growth in highly interactive online kids' classes. 

Furthermore, I spearheaded a cross-functional Standard Operating Procedure (SOP) that aligned 5 core roles (Data Analytics, Courseware Product, User Data, Interaction Design, and Pedagogy) into a unified optimization closed-loop.

### Core Outcomes
* **Leap in Product Experience & Retention:** Successfully optimized core interactive course content. A/B testing verified that the optimized courses achieved a **31% increase in user satisfaction** and an **18% lift in user retention**.
* **Boosted Organizational R&D Efficiency:** Established a "Courseware Optimization Database," solidifying it as the core reference standard for the Pedagogy and Interaction departments. This boosted human resource efficiency by **30%+** and reduced average course production time from **30 hours to 20 hours**.

---

## Repository File Structure

To ensure full transparency and reproducibility of the analytical pipeline, this repository is organized as follows:

```text
Data-Driven-Product-Growth/
├── 00_Environment_Setup/          # Database schemas & automated data synthesis
│   ├── ddl_schema.sql             # Table structures (fact_event_streams, etc.)
│   └── mock_data_generator.py     # Python script with weighted anomaly logic
├── 01_SQL_Scripts/                # Core analytical logic
│   ├── micro_funnel_bpse.sql      # B-P-S-E granular funnel & JSON parsing
│   └── anomaly_detection.sql      # Automated secondary error rate calculations
└── images/                        # Visual assets (SOPs, Mindmaps, UI comparisons)
```

---

## Strategy & Execution

### 1. Proactive Anomaly Detection Mechanism
I led a **2-person analytics team** to build a 0-to-1 **"Abnormal Product Content Screening Mechanism."** By quantifying raw event logs, we pinpointed interaction nodes that caused repeated user errors and high-frequency misoperations, providing clear, data-driven guidance for content R&D.

### 2. Cross-Department Standard Operating Procedure (SOP)
I spearheaded the creation of the **"Abnormal Content Optimization Workflow V1.0"**. This mechanism successfully aligned 5 core roles—**Data Analytics, Courseware Product, User Data, Interaction Design, and Pedagogy**—establishing a standardized business closed-loop.

![SOP Workflow](images/SOP_workflow.png)

*(Above: The SOP Synergy Mechanism spanning from requirement collection to optimization implementation.)*

---

## Core Data Analysis: Granular Behavior Trajectory Tracking

I abandoned coarse-grained page funnels. Instead, by parsing unstructured raw data, I built a highly granular **User Behavior Trajectory Tree**, tracking the complete user journey from:  
`Entering Module -> Encountering Task -> Specific Scene -> Micro-interaction`.

<details>
<summary><b>Click to Expand: Core SQL for Funnel Trajectory & JSON Parsing</b></summary>

```sql
-- Purpose: Parse underlying JSON event tracking logs to build a 4-level user behavior trajectory tree.
-- Highlight: Use get_json_object to precisely parse unstructured behavioral data.

WITH 
-- 1. Limit to first-lesson users (Exclude review data pollution)
First_Lesson_Users AS (
    SELECT student_id, lesson_code
    FROM (
        SELECT user_id as student_id, lesson_code,
               ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY start_time ASC) as rn
        FROM app_log_db.fact_classroom_sessions 
        WHERE status = 1 AND start_time IS NOT NULL 
          AND data_dt BETWEEN '2023-10-01' AND '2023-10-21' 
    ) a WHERE rn = 1
),
-- 2. Track entry points for core micro-interactions
Enter_Interaction AS (
    SELECT uid, lesson_code,
           get_json_object(payload, '$.interaction_code') as interaction_code, 
           get_json_object(payload, '$.trace_id') as trace_id
    FROM app_log_db.fact_event_streams 
    WHERE data_dt BETWEEN '2023-10-01' AND '2023-10-21' 
      AND event = 'enter-interaction' AND role_type = 'student' 
),
-- 3. Track exit/completion points
Leave_Interaction AS (
    SELECT uid, lesson_code,
           get_json_object(payload, '$.interaction_code') as interaction_code,
           get_json_object(payload, '$.trace_id') as trace_id
    FROM app_log_db.fact_event_streams 
    WHERE data_dt BETWEEN '2023-10-01' AND '2023-10-21' 
      AND event = 'leave-interaction' AND role_type = 'student' 
)
-- 4. Aggregate conversion rates to locate defect nodes
SELECT 
    e.lesson_code,
    e.interaction_code,
    COUNT(DISTINCT f.student_id) AS total_class_users,
    COUNT(DISTINCT e.uid) AS users_entering_interaction,
    COUNT(DISTINCT l.uid) AS users_completing_interaction,
    ROUND(COUNT(DISTINCT l.uid)/COUNT(DISTINCT e.uid), 4) AS interaction_completion_rate
FROM First_Lesson_Users f
LEFT JOIN Enter_Interaction e ON f.student_id = e.uid AND f.lesson_code = e.lesson_code
LEFT JOIN Leave_Interaction l ON e.interaction_code = l.interaction_code AND e.trace_id = l.trace_id AND e.uid = l.uid
GROUP BY e.lesson_code, e.interaction_code;
