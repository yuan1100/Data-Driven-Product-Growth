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

#### 第二块：策略与折叠 SQL 代码
*(接着在下面空一行，粘贴这一块)*

```markdown
## Strategy & Execution

### 1. Proactive Anomaly Detection Mechanism
By quantifying raw event logs, we pinpointed interaction nodes that caused repeated user errors and high-frequency misoperations, providing clear, data-driven guidance for content R&D.

### 2. Cross-Department Standard Operating Procedure (SOP)
This mechanism successfully established a standardized business closed-loop from problem identification to optimization implementation.

![SOP Workflow](images/SOP_workflow.png)

---

## Core Data Analysis: Granular Behavior Trajectory Tracking

I abandoned coarse-grained page funnels. Instead, by parsing unstructured raw data, I built a highly granular **User Behavior Trajectory Tree**, tracking the complete user journey from:  
`Entering Module -> Encountering Task -> Specific Scene -> Micro-interaction`.

<details>
<summary><b>Click to Expand: Core SQL for Funnel Trajectory & JSON Parsing</b></summary>

```sql
-- Purpose: Parse underlying JSON event tracking logs to build a 4-level user behavior trajectory tree.

WITH 
-- 1. Limit to first-lesson users
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
-- 2. Track entry points
Enter_Interaction AS (
    SELECT uid, lesson_code,
           get_json_object(payload, '$.interaction_code') as interaction_code, 
           get_json_object(payload, '$.trace_id') as trace_id
    FROM app_log_db.fact_event_streams 
    WHERE data_dt BETWEEN '2023-10-01' AND '2023-10-21' 
      AND event = 'enter-interaction' AND role_type = 'student' 
)
-- (Query simplified for display, please refer to 01_SQL_Scripts for full logic)
SELECT * FROM Enter_Interaction LIMIT 10;

```markdown
---

## Case Studies: Data-Driven Product Optimization

Using the trajectory model, I located and optimized numerous interaction defects causing high-frequency misoperations. Below are 3 typical cases:

| Task / Scene | Data Insight (Root Cause Drill-down) | Business Action (Optimization) |
| :--- | :--- | :--- |
| **1. Quantity Division**<br>*(Bones)* | **75.1% Error Rate:** Users only divided the bones physically but didn't type the numbers. | Added voice prompts and highlighted brackets; adjusted evaluation logic. |
| **2. Find the Cylinder**<br>*(Bucket)* | **72.0% Error Rate:** The visual perspective design caused visual ambiguity. | Increased the visual difference between the top and bottom diameters. |
| **3. Connecting Curves**<br>*(Wavy Lines)* | **38.9% Error Rate:** Users only selected one of the wavy lines and rushed to the next step. | Added a "total line segment count prompt" and a "Submit button". |

---

## Strategic Evaluation Framework

To ensure sustainable iteration, I systematically broke down the core metrics of **"promoting class completion rates and first-attempt accuracy rates,"** establishing a structured evaluation framework for the entire R&D center.

![Project Mindmap](images/project_mindmap.png)
