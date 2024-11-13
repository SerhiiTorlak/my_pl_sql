--Фрагмент специфікації пакету з оголошенням змінних та фукнції
create package util as

 TYPE region_cnt_emp_rec IS RECORD
                               (
                                   region_name hr.regions.region_name%TYPE,
                                   count_emp   NUMBER
                               );
    TYPE region_cnt_emp_tab IS TABLE OF region_cnt_emp_rec;  

    FUNCTION get_region_cnt_emp(p_department_id IN NUMBER DEFAULT NULL) RETURN region_cnt_emp_tab PIPELINED;

end util;
/

--фрагмент тіла пакету з функцією із завдання
create package body util as

FUNCTION get_region_cnt_emp(p_department_id IN NUMBER DEFAULT NULL) RETURN region_cnt_emp_tab PIPELINED IS

        out_rec region_cnt_emp_tab := region_cnt_emp_tab(); 
        l_cur   SYS_REFCURSOR;

    begin

        OPEN l_cur FOR
            select r.REGION_NAME, count(e.EMPLOYEE_ID) as count_emp
            from hr.regions r
                     left join hr.COUNTRIES using (region_id)
                     left join hr.LOCATIONS using (country_id)
                     left join hr.DEPARTMENTS d using (location_id)
                     left join hr.EMPLOYEES e on d.department_id = e.department_id
            where (e.department_id = p_department_id or p_department_id is null)
            group by r.REGION_NAME;

        BEGIN
            LOOP
                EXIT WHEN l_cur%NOTFOUND; --зупиняємо курсор, коли даних не залишилось
                FETCH l_cur BULK COLLECT
                    INTO out_rec;
                FOR i IN 1 .. out_rec.count
                    LOOP
                        PIPE ROW (out_rec(i));
                    END LOOP;
            END LOOP;
            CLOSE l_cur; --закриваємо курсор

        EXCEPTION
            WHEN OTHERS THEN
                IF (l_cur%ISOPEN) THEN
                    CLOSE l_cur;
                    RAISE;
                ELSE
                    RAISE;
                END IF;
        END;

    end get_region_cnt_emp;
    
end util;
/