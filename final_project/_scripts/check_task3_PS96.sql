SELECT *
FROM EMPLOYEES
where EMPLOYEE_ID > 200;

BEGIN
    util.fire_an_employee(229);
END;
/

select *
from EMPLOYEES_HISTORY
;