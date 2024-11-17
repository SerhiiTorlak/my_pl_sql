--перевіряємо максимальне значення employee_id
SELECT max(employee_id)
FROM employees
;

SELECT *
FROM employees
where EMPLOYEE_ID > 200
;

select *
from DEPARTMENTS
;

BEGIN
    util.add_employee(p_first_name => 'William',
                 p_last_name => 'Fay',
                 p_email => 'WFAY',
                 p_phone_number => '603.123.6666',
                 p_job_id => 'MK_',
                 p_salary => 6000,
                 p_department_id => 100);
END;
/

SELECT *
FROM logs
where trunc(LOG_DATE, 'DD') > date '2024-11-15'
;