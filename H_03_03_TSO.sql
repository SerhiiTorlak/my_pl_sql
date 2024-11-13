--специфікація пакету
create package util as
    function get_job_title(p_emp_id in number) return varchar2;
    function get_dep_name(p_emp_id in number) return varchar2;
    procedure del_jobs(p_job_id in varchar2,
                       po_result out varchar2);
end util;
/

--тіло пакету
create package body util as

    --функція отримання назви посади за ід працівника
    function get_job_title(p_emp_id in number) return varchar2 as

        v_job_title SERGIYI_ONU.JOBS.JOB_TITLE%type;
    begin

        select j.JOB_TITLE
        into v_job_title
        from SERGIYI_ONU.EMPLOYEES e
                 join SERGIYI_ONU.JOBS j using (JOB_ID)
        where e.EMPLOYEE_ID = p_emp_id;

        return v_job_title;
    end get_job_title;

    --функія отримання назви департаменту за ід працівника
    function get_dep_name(p_emp_id in number) return varchar2 is

        v_dept_name SERGIYI_ONU.DEPARTMENTS.DEPARTMENT_NAME%type;

    begin

        select d.DEPARTMENT_NAME
        into v_dept_name
        from SERGIYI_ONU.EMPLOYEES e
                 join SERGIYI_ONU.DEPARTMENTS d using (DEPARTMENT_ID)
        where e.EMPLOYEE_ID = p_emp_id;

        return v_dept_name;

    end get_dep_name;

    --процедура видалення посади
    procedure del_jobs(p_job_id in varchar2,
                       po_result out varchar2) is
        v_check_job_id number;

    begin

        select count(*)
        into v_check_job_id
        from SERGIYI_ONU.JOBS j
        where j.JOB_ID = p_job_id;

        if v_check_job_id = 0 then
            po_result := 'Посади ' || p_job_id || ' не існує';
        else
            delete from SERGIYI_ONU.JOBS j where j.JOB_ID = p_job_id;
            po_result := 'Посада ' || p_job_id || ' успішно видалена';
        end if;

    end del_jobs;

end util;
/

--виклик функцій з пакету
select EMPLOYEE_ID,
       FIRST_NAME,
       LAST_NAME,
       util.get_job_title(e.EMPLOYEE_ID) as job_title,
       util.get_dep_name(e.EMPLOYEE_ID)  as department_name
from SERGIYI_ONU.EMPLOYEES e;

--виклик процедури з пакету
declare
v_res varchar2(50);
begin
    util.DEL_JOBS(p_job_id => 'IT_', po_result => v_res);
    DBMS_OUTPUT.put_line(v_res);
end;
