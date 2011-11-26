set linesize 200
col LAST_START_DATE format a35
col NEXT_RUN_DATE format a35

select job_name, LAST_START_DATE, NEXT_RUN_DATE, STATE, FAILURE_COUNT  from user_scheduler_jobs;
