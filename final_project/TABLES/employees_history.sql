create table employees_history as
select employee_id,
       first_name,
       last_name,
       email,
       phone_number,
       hire_date,
       hire_date as fire_date,
       job_id as last_job_id,
       salary as last_salary,
       manager_id as last_manager_id,
       department_id as last_department_id
from EMPLOYEES
where 1 != 1