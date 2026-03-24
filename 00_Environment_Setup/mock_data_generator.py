"""
Data Mock Generator for EdTech Product Growth Analysis
Author: Data Analytics Manager
Description: 
Generates synthetic data for fact_classroom_sessions and fact_event_streams.
Strictly follows SQL schema and JSON parsing requirements.
"""

import pandas as pd
import random
import json
from datetime import datetime, timedelta

# Time window configuration
START_DATE = datetime.strptime('2023-10-01', '%Y-%m-%d')
END_DATE = datetime.strptime('2023-10-21', '%Y-%m-%d')

# Core interaction codes
INTERACTION_CODES = ['Scene1_Bone_Division', 'Scene2_Bucket_Select', 'Scene3_Wave_Line']

def random_date(start, end):
    """Generates a random datetime within the specified range."""
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)

def generate_mock_data(num_sessions=1500):
    sessions = []
    events = []
    
    print("Starting to generate mock data...")
    
    for _ in range(num_sessions):
        user_id = random.randint(10000, 99999)
        lesson_code = f"Math_L{random.randint(1, 5)}"
        
        # 1. Classroom sessions logic
        start_time = random_date(START_DATE, END_DATE)
        finish_time = start_time + timedelta(minutes=random.randint(20, 40))
        data_dt = start_time.strftime('%Y-%m-%d')
        status = 1 if random.random() > 0.05 else 0 
        
        sessions.append([
            user_id, lesson_code, 
            start_time.strftime('%Y-%m-%d %H:%M:%S'), 
            finish_time.strftime('%Y-%m-%d %H:%M:%S'), 
            status, data_dt
        ])
        
        # 2. Event stream logic
        num_interactions = random.randint(3, 8)
        current_time = start_time + timedelta(minutes=1)
        
        for _ in range(num_interactions):
            interaction_code = random.choice(INTERACTION_CODES)
            trace_id = f"tr_{random.randint(100, 999)}"
            
            # (A) EVENT: enter-interaction (Match SQL parsing key)
            payload_enter = json.dumps({"interaction_code": interaction_code, "trace_id": trace_id})
            events.append([
                user_id, 'enter-interaction', 'student', payload_enter, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(5, 30))
            
            # (B) EVENT: trigger-branch
            branch_choice = random.choices(
                ['correct', 'frequent_error', 'secondary_error'], 
                weights=[0.5, 0.3, 0.2]
            )[0]
            
            payload_branch = json.dumps({
                "interaction_code": interaction_code, 
                "branch_type": branch_choice, 
                "trace_id": trace_id
            })
            events.append([
                user_id, 'trigger-branch', 'student', payload_branch, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(2, 10))
            
            # (C) EVENT: leave-interaction
            payload_leave = json.dumps({"interaction_code": interaction_code, "trace_id": trace_id})
            events.append([
                user_id, 'leave-interaction', 'student', payload_leave, 
                current_time.strftime('%Y-%m-%d %H:%M:%S'), data_dt
            ])
            
            current_time += timedelta(seconds=random.randint(10, 60))

    # 3. Export to CSV
    df_sessions = pd.DataFrame(sessions, columns=['user_id', 'lesson_code', 'start_time', 'finish_time', 'status', 'data_dt'])
    df_events = pd.DataFrame(events, columns=['uid', 'event', 'role_type', 'payload', 'ctime', 'data_dt'])
    
    df_sessions.to_csv('fact_classroom_sessions.csv', index=False)
    df_events.to_csv('fact_event_streams.csv', index=False)
    
    print(f"Success: Generated {len(df_sessions)} sessions and {len(df_events)} events.")

if __name__ == "__main__":
    generate_mock_data(num_sessions=1500)
