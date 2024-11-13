declare
    v_employee_id HR.EMPLOYEES.EMPLOYEE_ID%TYPE := 110;
    v_job_id      HR.EMPLOYEES.JOB_ID%TYPE;
    v_job_title   HR.JOBS.JOB_TITLE%TYPE;
begin

    select e.JOB_ID
    into v_job_id
    from HR.EMPLOYEES e
    where e.EMPLOYEE_ID = v_employee_id;

    select j.JOB_TITLE
    into v_job_title
    from HR.JOBS j
    where j.JOB_ID = v_job_id;

    DBMS_OUTPUT.put_line(v_job_title);
end;
/