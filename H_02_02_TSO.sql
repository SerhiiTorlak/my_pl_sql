declare
    v_def_percent VARCHAR2(30);
    v_percent     VARCHAR2(5);
    v_dep_id      NUMBER := 80;
begin

    for cc in (select e.COMMISSION_PCT * 100             as percent_of_salary
                    , e.FIRST_NAME || ' ' || e.LAST_NAME as emp_name
                    , e.MANAGER_ID
               from HR.EMPLOYEES e
               where e.DEPARTMENT_ID = v_dep_id
               order by e.FIRST_NAME)
        loop
            if cc.MANAGER_ID = 100 then
                DBMS_OUTPUT.put_line('—п≥вроб≥тник - ' || cc.emp_name || ', в≥дсоток до зарплати нараз≥ заборонений');
                continue;
            end if;

            if cc.percent_of_salary between 10 and 20 then
                v_def_percent := 'м≥н≥мальний';
            elsif cc.percent_of_salary between 25 and 30 then
                v_def_percent := 'середн≥й';
            elsif cc.percent_of_salary between 35 and 40 then
                v_def_percent := 'максимальний';
            end if;

            v_percent := concat(cc.percent_of_salary, '%');

            DBMS_OUTPUT.put_line('—п≥вроб≥тник - ' || cc.emp_name ||
                                 '; в≥дсоток до зарплати - ' || v_percent ||
                                 '; опис в≥дсотку - ' || v_def_percent);

        end loop;

end;
/