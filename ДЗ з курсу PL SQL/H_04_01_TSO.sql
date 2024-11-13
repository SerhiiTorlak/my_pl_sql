create package body util as

    c_percent_of_min_salary constant number := 1.5;

    function add_years(p_date IN date default sysdate,
                       p_year in number) return date is

        v_date   date;
        v_months number := p_year * 12;

    begin

        select add_months(p_date, v_months)
        into v_date
        from dual;

        return v_date;

    end add_years;

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

    --процедура перевірки, який день сьогодні - вихідний чи робочий
    procedure check_work_time is

    begin
        if to_char(sysdate, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN') in ('SAT', 'SUN') then
            raise_application_error(-20205, 'Ви можете вносити зміни лише у робочі дні');
        end if;

    end check_work_time;

    --процедура щось там
    procedure add_new_job(p_job_id in varchar2,
                          p_job_title in varchar2,
                          p_min_salary in number,
                          p_max_salary in number default null,
                          po_err out varchar2) is

        v_max_salary SERGIYI_ONU.JOBS.JOB_ID%type;
        salary_err EXCEPTION;

    begin

        check_work_time;

        if p_max_salary is null then
            v_max_salary := p_min_salary * c_percent_of_min_salary;
        else
            v_max_salary := p_max_salary;
        end if;

        BEGIN

            if (p_min_salary < gc_min_salary or p_max_salary < gc_min_salary) then
                raise salary_err;

            else
                insert into SERGIYI_ONU.jobs (JOB_ID, JOB_TITLE, MIN_SALARY, MAX_SALARY)
                values (p_job_id, p_job_title, p_min_salary, v_max_salary);
                po_err := 'Посада ' || p_job_id || ' успішно додана';
            end if;

        EXCEPTION
            when salary_err then raise_application_error(-20001, 'Передана зарплата менша за 2000');
            when dup_val_on_index then raise_application_error(-20002, 'Посада ' || p_job_id || ' вже існує');
            when others then raise_application_error(-20003, 'Виникла помилка при додаванні нової посади, ' || SQLERRM);

        END;

        --commit;

    end add_new_job;

    --процедура з прикладом використання автономної транзакції
    PROCEDURE update_balance(p_employee_id IN NUMBER,
                             p_balance IN NUMBER) IS
        v_balance_new balance.balance%TYPE;
        v_balance_old balance.balance%TYPE;
        v_message     logs.message%TYPE;

    BEGIN

        SELECT balance
        INTO v_balance_old
        FROM balance b
        WHERE b.employee_id = p_employee_id
            FOR UPDATE; -- Блокуємо рядок для оновлення

        IF v_balance_old >= p_balance THEN
            UPDATE balance b
            SET b.balance = v_balance_old - p_balance
            WHERE employee_id = p_employee_id
            RETURNING b.balance INTO v_balance_new; -- щоб не робити новий SELECT INTO
        ELSE
            v_message := 'Employee_id = ' || p_employee_id || '. Недостатньо коштів на рахунку. Поточний баланс ' ||
                         v_balance_old || ', спроба зняття ' || p_balance;
            raise_application_error(-20001, v_message);
        END IF;
        v_message := 'Employee_id = ' || p_employee_id || '. Кошти успішно зняті з рахунку. Було ' || v_balance_old ||
                     ', стало ' || v_balance_new;
        dbms_output.put_line(v_message);
        to_log(p_appl_proc => 'util.update_balance', p_message => v_message);
        /*IF 1 = 0 THEN -- зімітуємо непередбачену помилку
            v_message := 'Непередбачена помилка';
            raise_application_error(-20001, v_message);
        END IF;*/
        COMMIT; -- зберігаємо новий баланс та знімаємо блокування в поточній транзакції
    EXCEPTION
        WHEN OTHERS THEN
            to_log(p_appl_proc => 'util.update_balance',
                   p_message => NVL(v_message, 'Employee_id = ' || p_employee_id || '. ' || SQLERRM));
            ROLLBACK; -- Відміняємо транзакцію у разі виникнення помилки
            raise_application_error(-20001, NVL(v_message, 'Невідома помилка'));
    END update_balance;

end util;
/