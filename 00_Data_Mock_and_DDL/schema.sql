-- Initial Setup: Create the analytics environment
CREATE DATABASE IF NOT EXISTS app_log_db;
USE app_log_db;

-- 1. Core Event Tracking Table (Stores raw JSON payloads)
-- This table is the primary source for behavioral trajectory and anomaly detection.
CREATE TABLE fact_event_streams (
    uid         INT             COMMENT 'Unique User Identifier',
    event       VARCHAR(50)     COMMENT 'Event Type: enter-element, trigger-branch, etc.',
    role_type   VARCHAR(20)     COMMENT 'Role constraint: student, teacher, etc.',
    payload     STRING          COMMENT 'JSON payload containing interaction_code, branch_type, etc.',
    ctime       TIMESTAMP       COMMENT 'Event generation timestamp',
    data_dt     DATE            COMMENT 'Partition date for query optimization'
) 
COMMENT 'Centralized repository for raw user interaction logs';

-- 2. Classroom Session Table
-- Used to identify first-lesson users and filter valid learning sessions.
CREATE TABLE fact_classroom_sessions (
    user_id     INT             COMMENT 'User ID of the learner',
    lesson_code VARCHAR(50)     COMMENT 'Unique identifier for the course lesson',
    start_time  TIMESTAMP       COMMENT 'Actual lesson start time',
    finish_time TIMESTAMP       COMMENT 'Lesson completion time',
    status      INT             COMMENT 'Session validity flag (1: Valid, 0: Invalid)',
    data_dt     DATE            COMMENT 'Partition date for query optimization'
) 
COMMENT 'Consolidated records of student classroom activities';

-- 3. Commercial/Order Fact Table
-- Linked to behavior data for ROI and LTV (Life Time Value) analysis.
CREATE TABLE fact_order_records (
    user_id     INT             COMMENT 'User ID associated with the purchase',
    order_id    VARCHAR(50)     COMMENT 'Unique transaction identifier',
    pay_time    TIMESTAMP       COMMENT 'Payment timestamp',
    pay_price   DECIMAL(10,2)   COMMENT 'Transaction amount',
    course_type INT             COMMENT 'Product category (1: Trial/Lead-gen, 2: Retention/Regular)'
) 
COMMENT 'Revenue and transaction history for commercial impact analysis';
