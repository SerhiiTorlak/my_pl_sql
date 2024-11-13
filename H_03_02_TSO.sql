create function get_dep_name(p_emp_id in number) return varchar2 is

    v_dept_name SERGIYI_ONU.DEPARTMENTS.DEPARTMENT_NAME%type;

begin

    select d.DEPARTMENT_NAME
    into v_dept_name
    from SERGIYI_ONU.EMPLOYEES e
             join SERGIYI_ONU.DEPARTMENTS d using (DEPARTMENT_ID)
    where e.EMPLOYEE_ID = p_emp_id;

    return v_dept_name;

end get_dep_name;
/


select EMPLOYEE_ID,
       FIRST_NAME,
       LAST_NAME,
       get_job_title(e.EMPLOYEE_ID) as job_title,
       get_dep_name(e.EMPLOYEE_ID)  as department_name
from SERGIYI_ONU.EMPLOYEES e;

