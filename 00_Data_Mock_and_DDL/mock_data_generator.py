"""
Data Mock Generator for EdTech Product Growth Analysis
Author: Data Analytics Manager
Description: 
Generates synthetic data for `fact_classroom_sessions` and `fact_event_streams`
to simulate user behavior trajectories and anomaly interactions (e.g., frequent errors, secondary errors).
Date Range: 2023-10-01 to 2023-10-21
"""

import pandas as pd
import random
import json
from datetime import datetime, timedelta

# Configuration: Anonymized time window
START_DATE = datetime.strptime('2023-10-01', '%Y-%m-%d')
END_DATE = datetime.strptime('2023-10-21', '%Y-%m-%d')

# Core interaction codes (Linked to project cases: Bone Division, Bucket Select, Wave Line)
INTERACTION_CODES = ['Scene1_Bone_Division', 'Scene2_Bucket_Select', 'Scene3_Wave_Line']

def random_date(start, end):
    """Generates a random datetime between two dates."""
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)

def generate_mock_data(num_sessions=1500):
    sessions = []
    events = []
    
    print("Starting to generate mock data for analysis...")
    
    for _ in range(num_sessions):
        user_id = random.randint(10000, 99999)
        lesson_code = f"Math_L{random.randint(1, 5)}"
        
        # 1. Generate Classroom Records (fact_classroom_sessions)
        start_time = random_date(START_DATE, END_DATE)
        finish_time = start_time + timedelta(minutes=random.randint(20, 40))
        data_dt = start_time.strftime('%Y-%m-%d')
        
        # Simulate 95% completion rate (status=1)
        status = 1 if random.random() > 0.05 else 0 
        
        sessions.append([
            user_id, lesson_code, 
            start_time.strftime('%Y-%m-%d %H:%M:%S'), 
            finish_time.strftime('%Y-%m-%d %H:%M:%S'), 
            status, data_dt
        ])
        
        # 2. Generate Event Streams (fact_event_streams)
        # Each session generates 3-8 micro-interaction behavioral nodes
        num_interactions = random.randint(3, 8)
        current_time = start_time + timedelta(minutes=1)
        
        for _ in range(num_interactions):
            interaction_code = random.choice(INTERACTION_CODES)
            trace_id = f"tr_{random.randint(1000,9999)}"
            
            # (A) EVENT: enter-element
            payload_enter = json.dumps({"code": interaction_code, "trace_id": trace_id})
            events.append([
                user_id, 'enter-element', 'student', payload_enter, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(5, 30))
            
            # (B) EVENT: trigger-branch 
            # Strategic weighting to trigger thresholds in anomaly_detection.sql
            branch_choice = random.choices(
                ['correct', 'frequent_error', 'secondary_error'], 
                weights=[0.5, 0.3, 0.2] 
            )[0] # Extract string from list
            
            payload_branch = json.dumps({
                "code": interaction_code, 
                "branch_type": branch_choice, 
                "trace_id": trace_id
            })
            events.append([
                user_id, 'trigger-branch', 'student', payload_branch, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(2, 10))
            
            # (C) EVENT: leave-element
            payload_leave = json.dumps({"code": interaction_code, "trace_id": trace_id})
            events.append([
                user_id, 'leave-element', 'student', payload_leave, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(10, 60))

    # 3. Convert to Pandas DataFrame and Export to CSV
    df_sessions = pd.DataFrame(sessions, columns=[
        'user_id', 'lesson_code', 'start_time', 'finish_time', 'status', 'data_dt'
    ])
    df_events = pd.DataFrame(events, columns=[
        'uid', 'event', 'role_type', 'payload', 'ctime', 'data_
