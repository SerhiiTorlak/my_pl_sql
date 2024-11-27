create PACKAGE util AS

    gc_min_salary CONSTANT NUMBER := 2000;
    gc_percent_of_min_salary CONSTANT NUMBER := 1.5;

    TYPE rec_value_list IS RECORD (value_list VARCHAR2(100));
    TYPE tab_value_list IS TABLE OF rec_value_list;

    TYPE rec_exchange IS RECORD
                         (
                             r030         NUMBER,
                             txt          VARCHAR2(100),
                             rate         NUMBER,
                             cur          VARCHAR2(100),
                             exchangedate DATE
                         );
    TYPE tab_exchange IS TABLE OF rec_exchange;

    TYPE region_cnt_emp_rec IS RECORD
                               (
                                   region_name hr.regions.region_name%TYPE,
                                   count_emp   NUMBER
                               );
    TYPE region_cnt_emp_tab IS TABLE OF region_cnt_emp_rec;

    FUNCTION get_region_cnt_emp(p_department_id IN NUMBER DEFAULT NULL) RETURN region_cnt_emp_tab PIPELINED;

    FUNCTION table_from_list(p_list_val IN VARCHAR2,
                             p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED;

    FUNCTION get_currency(p_currency IN VARCHAR2 DEFAULT 'USD',
                          p_exchangedate IN DATE DEFAULT SYSDATE) RETURN tab_exchange PIPELINED;

    FUNCTION add_years(p_date IN DATE DEFAULT SYSDATE,
                       p_year IN NUMBER) RETURN DATE;

    FUNCTION get_job_title(p_emp_id IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_dep_name(p_emp_id IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_sum_price_sales(p_table IN VARCHAR2) RETURN NUMBER;

    PROCEDURE del_jobs(p_job_id IN VARCHAR2,
                       po_result OUT VARCHAR2);

    PROCEDURE add_new_job(p_job_id IN VARCHAR2,
                          p_job_title IN VARCHAR2,
                          p_min_salary IN NUMBER,
                          p_max_salary IN NUMBER DEFAULT NULL,
                          po_err OUT VARCHAR2);

    PROCEDURE update_balance(p_employee_id IN NUMBER,
                             p_balance IN NUMBER);

    PROCEDURE add_employee(p_first_name IN VARCHAR2,
                           p_last_name IN VARCHAR2,
                           p_email IN VARCHAR2,
                           p_phone_number IN VARCHAR2,
                           p_hire_date IN DATE DEFAULT trunc(SYSDATE, 'dd'),
                           p_job_id IN VARCHAR2,
                           p_salary IN NUMBER,
                           p_commission_pct IN NUMBER DEFAULT NULL,
                           p_manager_id IN NUMBER DEFAULT 100,
                           p_department_id IN NUMBER,
                           p_auto_commit BOOLEAN DEFAULT FALSE);

    PROCEDURE fire_an_employee(p_employee_id IN NUMBER,
                               p_auto_commit BOOLEAN DEFAULT FALSE);

    PROCEDURE change_attribute_employee(p_employee_id IN NUMBER,
                                        p_first_name IN VARCHAR2 DEFAULT NULL,
                                        p_last_name IN VARCHAR2 DEFAULT NULL,
                                        p_email IN VARCHAR2 DEFAULT NULL,
                                        p_phone_number IN VARCHAR2 DEFAULT NULL,
                                        p_job_id IN VARCHAR2 DEFAULT NULL,
                                        p_salary IN NUMBER DEFAULT NULL,
                                        p_commission_pct IN NUMBER DEFAULT NULL,
                                        p_manager_id IN NUMBER DEFAULT NULL,
                                        p_department_id IN NUMBER DEFAULT NULL);

    PROCEDURE copy_table(p_source_scheme IN VARCHAR2,
                         p_target_scheme IN VARCHAR2 DEFAULT USER,
                         p_list_table IN VARCHAR2,
                         p_copy_data IN BOOLEAN DEFAULT FALSE,
                         po_result OUT VARCHAR2,
                         p_auto_commit BOOLEAN DEFAULT FALSE);

END util;
/

create PACKAGE BODY util AS

    FUNCTION get_region_cnt_emp(p_department_id IN NUMBER DEFAULT NULL) RETURN region_cnt_emp_tab PIPELINED IS

        out_rec region_cnt_emp_tab := region_cnt_emp_tab();
        l_cur   SYS_REFCURSOR;

    BEGIN

        OPEN l_cur FOR
            SELECT r.REGION_NAME, count(e.EMPLOYEE_ID) AS count_emp
            FROM hr.regions r
                     LEFT JOIN hr.COUNTRIES USING (region_id)
                     LEFT JOIN hr.LOCATIONS USING (country_id)
                     LEFT JOIN hr.DEPARTMENTS d USING (location_id)
                     LEFT JOIN hr.EMPLOYEES e ON d.department_id = e.department_id
            WHERE (e.department_id = p_department_id OR p_department_id IS NULL)
            GROUP BY r.REGION_NAME;

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

    END get_region_cnt_emp;


    FUNCTION table_from_list(p_list_val IN VARCHAR2,
                             p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED IS

        out_rec tab_value_list := tab_value_list(); --ініціалізація змінної
        l_cur   SYS_REFCURSOR;

    begin

        OPEN l_cur FOR
            SELECT TRIM(REGEXP_SUBSTR(p_list_val, '[^' || p_separator || ']+', 1, LEVEL)) AS cur_value
            FROM dual
            CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;

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

    end table_from_list;

    FUNCTION get_currency(p_currency IN VARCHAR2 DEFAULT 'USD',
                          p_exchangedate IN DATE DEFAULT SYSDATE) RETURN tab_exchange PIPELINED IS

        out_rec tab_exchange := tab_exchange();
        l_cur   SYS_REFCURSOR;

    begin

        OPEN l_cur FOR
            SELECT tt.r030, tt.txt, tt.rate, tt.cur, TO_DATE(tt.exchangedate, 'dd.mm.yyyy') AS exchangedate
            FROM (SELECT get_needed_curr(p_valcode => p_currency, p_date => p_exchangedate) AS json_value
                  FROM dual)
                     CROSS JOIN json_table
                                (json_value, '$[*]'
                                 COLUMNS
                                     ( r030 NUMBER PATH '$.r030',
                                     txt VARCHAR2(100) PATH '$.txt',
                                     rate NUMBER PATH '$.rate',
                                     cur VARCHAR2(100) PATH '$.cc',
                                     exchangedate VARCHAR2(100) PATH '$.exchangedate'
                                     )
                                ) TT;

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

    END get_currency;

    FUNCTION add_years(p_date IN DATE DEFAULT SYSDATE,
                       p_year IN NUMBER) RETURN DATE IS

        v_date   DATE;
        v_months NUMBER := p_year * 12;

    BEGIN

        SELECT add_months(p_date, v_months)
        INTO v_date
        FROM dual;

        RETURN v_date;

    END add_years;

--функція отримання назви посади за ід працівника
    FUNCTION get_job_title(p_emp_id IN NUMBER) RETURN VARCHAR2 AS

        v_job_title SERGIYI_ONU.JOBS.JOB_TITLE%TYPE;
    BEGIN

        SELECT j.JOB_TITLE
        INTO v_job_title
        FROM SERGIYI_ONU.EMPLOYEES e
                 JOIN SERGIYI_ONU.JOBS j USING (JOB_ID)
        WHERE e.EMPLOYEE_ID = p_emp_id;

        RETURN v_job_title;
    END get_job_title;

--функія отримання назви департаменту за ід працівника
    FUNCTION get_dep_name(p_emp_id IN NUMBER) RETURN VARCHAR2 IS

        v_dept_name SERGIYI_ONU.DEPARTMENTS.DEPARTMENT_NAME%TYPE;

    BEGIN

        SELECT d.DEPARTMENT_NAME
        INTO v_dept_name
        FROM SERGIYI_ONU.EMPLOYEES e
                 JOIN SERGIYI_ONU.DEPARTMENTS d USING (DEPARTMENT_ID)
        WHERE e.EMPLOYEE_ID = p_emp_id;

        RETURN v_dept_name;

    END get_dep_name;

    FUNCTION get_sum_price_sales(p_table IN VARCHAR2) RETURN NUMBER IS
        v_sql_code VARCHAR2(50);
        v_message  logs.message%TYPE;
        v_sum      NUMBER;
    BEGIN

        IF lower(p_table) NOT IN ('products', 'products_old') THEN
            v_message := 'Неприпустиме значеня! Отримано ' || p_table || ' , а очікується products або products_old';
            to_log(p_appl_proc => 'util.get_sum_price_sales', p_message => v_message);
            raise_application_error(-20001, v_message);
        END IF;

        v_sql_code := 'SELECT SUM(p.PRICE_SALES) from hr.' || p_table || ' p';

        EXECUTE IMMEDIATE v_sql_code INTO v_sum;

        RETURN v_sum;

    END get_sum_price_sales;

--процедура перевірки, який день сьогодні - вихідний чи робочий
    FUNCTION check_work_time RETURN BOOLEAN IS

        v_check BOOLEAN;

    BEGIN
        IF to_char(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN') IN ('SAT', 'SUN')
            OR to_char(SYSDATE, 'HH24:MI') <= '07:59'
            OR to_char(SYSDATE, 'HH24:MI') >= '18:01' THEN
            v_check := FALSE;
        ELSE
            v_check := TRUE;
        END IF;

        RETURN v_check;

    END check_work_time;

--процедура додавання нової посади
    PROCEDURE add_new_job(p_job_id IN VARCHAR2,
                          p_job_title IN VARCHAR2,
                          p_min_salary IN NUMBER,
                          p_max_salary IN NUMBER DEFAULT NULL,
                          po_err OUT VARCHAR2) IS

        v_max_salary SERGIYI_ONU.JOBS.JOB_ID%TYPE;
        salary_err EXCEPTION;

    BEGIN

        IF NOT check_work_time THEN
            raise_application_error(-20205, 'Ви можете вносити зміни лише у робочі дні');
        END IF;

        IF p_max_salary IS NULL THEN
            v_max_salary := p_min_salary * gc_percent_of_min_salary;
        ELSE
            v_max_salary := p_max_salary;
        END IF;

        BEGIN

            IF (p_min_salary < gc_min_salary OR p_max_salary < gc_min_salary) THEN
                RAISE salary_err;

            ELSE
                INSERT INTO SERGIYI_ONU.jobs (JOB_ID, JOB_TITLE, MIN_SALARY, MAX_SALARY)
                VALUES (p_job_id, p_job_title, p_min_salary, v_max_salary);
                po_err := 'Посада ' || p_job_id || ' успішно додана';
            END IF;

        EXCEPTION
            WHEN salary_err THEN raise_application_error(-20001, 'Передана зарплата менша за 2000');
            WHEN dup_val_on_index THEN raise_application_error(-20002, 'Посада ' || p_job_id || ' вже існує');
            WHEN OTHERS THEN raise_application_error(-20003, 'Виникла помилка при додаванні нової посади, ' || SQLERRM);

        END;

        --commit;

    END add_new_job;

--процедура видалення посади
    PROCEDURE del_jobs(p_job_id IN VARCHAR2,
                       po_result OUT VARCHAR2) IS

        v_delete_no_data_found EXCEPTION;

    BEGIN

        IF NOT check_work_time THEN
            raise_application_error(-20205, 'Ви можете вносити зміни лише у робочі дні');
        END IF;

        BEGIN

            DELETE FROM SERGIYI_ONU.JOBS j WHERE j.JOB_ID = p_job_id;

            IF SQL%ROWCOUNT = 0 THEN
                RAISE v_delete_no_data_found;
            END IF;

        EXCEPTION
            WHEN v_delete_no_data_found THEN raise_application_error(-20004, 'Посади ' || p_job_id || ' не існує');

        END;

        po_result := 'Посада ' || p_job_id || ' успішно видалена';

    END del_jobs;

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

    PROCEDURE add_employee(p_first_name IN VARCHAR2,
                           p_last_name IN VARCHAR2,
                           p_email IN VARCHAR2,
                           p_phone_number IN VARCHAR2,
                           p_hire_date IN DATE DEFAULT trunc(SYSDATE, 'dd'),
                           p_job_id IN VARCHAR2,
                           p_salary IN NUMBER,
                           p_commission_pct IN NUMBER DEFAULT NULL,
                           p_manager_id IN NUMBER DEFAULT 100,
                           p_department_id IN NUMBER,
                           p_auto_commit BOOLEAN DEFAULT FALSE) IS

        v_message logs.message%TYPE;

    BEGIN

        log_util.log_start(p_proc_name => 'add_employee');

        --перевіримо для початку робочий час
        IF NOT check_work_time() THEN
            v_message := 'Ви можете додавати нового співробітника лише в робочий час';
            raise_application_error(-20201, v_message);
        END IF;

        --перевіряємо, чи існує запрошений job_id
        <<search_job_id>>
        FOR c IN (
            SELECT 1
            FROM sergiyi_onu.jobs j
            WHERE j.job_id = p_job_id
            HAVING COUNT(*) = 0)
            LOOP
                v_message := 'Введено неіснуючий код посади';
                raise_application_error(-20002, v_message);
            END LOOP search_job_id;

        --перевіряємо, чи існує запрошений department_id
        <<search_department_id>>
        FOR c IN (
            SELECT 1
            FROM sergiyi_onu.departments d
            WHERE d.department_id = p_department_id
            HAVING COUNT(*) = 0)
            LOOP
                v_message := 'Введено неіснуючий ідентифікатор відділу';
                raise_application_error(-20003, v_message);
            END LOOP search_department_id;

        --перевіряємо зарплату
        <<search_salary>>
        FOR c IN (
            SELECT 1
            FROM sergiyi_onu.jobs j
            WHERE p_salary BETWEEN j.min_salary AND j.max_salary
            HAVING COUNT(*) = 0)
            LOOP
                v_message := 'Введено неприпустиму заробітну плату для даного коду посади';
                raise_application_error(-20004, v_message);
            END LOOP search_salary;

        --додати нового працівника в таблицю
        <<insert_new_emp>>
        BEGIN
            INSERT INTO sergiyi_onu.employees (employee_id, first_name, last_name, email, phone_number, hire_date,
                                               job_id, salary, commission_pct, manager_id, department_id)
            VALUES (emp_seq.NEXTVAL, p_first_name, p_last_name, p_email, p_phone_number, p_hire_date,
                    p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id);

        EXCEPTION
            WHEN OTHERS THEN
                log_util.log_error(p_proc_name => 'add_employee', p_sqlerrm => SQLERRM);
                v_message := 'Під час додавання нового співробітника виникла помилка. Деталі: ' || SQLERRM;
                raise_application_error(-20005, v_message);

        END insert_new_emp;

        v_message := 'Співробітник ' || p_first_name || ' ' || p_last_name || ', ' || p_job_id || ', ' ||
                     p_department_id || ' успішно додано до системи';

        log_util.log_finish(p_proc_name => 'add_employee', p_text => v_message);

        IF p_auto_commit THEN
            COMMIT;
        END IF;

    END add_employee;

    PROCEDURE fire_an_employee(p_employee_id IN NUMBER,
                               p_auto_commit BOOLEAN DEFAULT FALSE) IS

        v_emp_name   employees.first_name%TYPE;
        v_emp_l_name employees.last_name%TYPE;
        v_job_id     employees.job_id%TYPE;
        v_dep_id     employees.department_id%TYPE;
        v_message    logs.message%TYPE;

    BEGIN

        log_util.log_start(p_proc_name => 'fire_an_employee');

        --перевіримо для початку робочий час
        IF NOT check_work_time() THEN
            v_message := 'Ви можете видаляти співробітника лише в робочий час';
            raise_application_error(-20001, v_message);
        END IF;

        SELECT e.first_name, e.last_name, e.job_id, e.department_id
        INTO v_emp_name, v_emp_l_name, v_job_id, v_dep_id
        FROM sergiyi_onu.employees e
        WHERE e.employee_id = p_employee_id;

        <<delete_emp>>
        BEGIN
            DELETE
            FROM sergiyi_onu.employees e
            WHERE e.employee_id = p_employee_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_util.log_error(p_proc_name => 'fire_an_employee', p_sqlerrm => SQLERRM);
                raise_application_error(-20006, 'При видаленні співробітника виникла помилка. Подробиці: ' || SQLERRM);
        END delete_emp;

        v_message := 'Співробітник ' || v_emp_name || ' ' || v_emp_l_name || ', ' || v_job_id || ', ' ||
                     v_dep_id || ' успішно видалений';

        log_util.log_finish(p_proc_name => 'fire_an_employee', p_text => v_message);

        IF p_auto_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN no_data_found
            THEN raise_application_error(-20005,
                                         'Переданий співробітник ' || p_employee_id || ' не існує. Код помилки: ' ||
                                         SQLERRM);

    END fire_an_employee;

    PROCEDURE change_attribute_employee(p_employee_id IN NUMBER,
                                        p_first_name IN VARCHAR2 DEFAULT NULL,
                                        p_last_name IN VARCHAR2 DEFAULT NULL,
                                        p_email IN VARCHAR2 DEFAULT NULL,
                                        p_phone_number IN VARCHAR2 DEFAULT NULL,
                                        p_job_id IN VARCHAR2 DEFAULT NULL,
                                        p_salary IN NUMBER DEFAULT NULL,
                                        p_commission_pct IN NUMBER DEFAULT NULL,
                                        p_manager_id IN NUMBER DEFAULT NULL,
                                        p_department_id IN NUMBER DEFAULT NULL) IS

        v_message  logs.message%TYPE;
        v_step     NUMBER := 0;
        v_sql_part VARCHAR2(500);
        v_sql      VARCHAR2(500);

    BEGIN

        log_util.log_start(p_proc_name => 'change_attribute_employee');

        IF COALESCE(p_first_name,
                    p_last_name,
                    p_email,
                    p_phone_number,
                    p_job_id,
                    to_char(p_salary),
                    to_char(p_commission_pct),
                    to_char(p_manager_id),
                    to_char(p_department_id)) IS NULL THEN

            log_util.log_finish(p_proc_name => 'change_attribute_employee', p_text => 'Немає данних для оновлення.');
            raise_application_error(-20007, 'Не вказаний жоден із параметрів для оновлення');

        END IF;

        --перевіряємо, чи є такий працівник
        <<search_employee>>
        FOR c IN (
            SELECT 1
            FROM sergiyi_onu.employees e
            WHERE e.employee_id = p_employee_id
            HAVING COUNT(*) = 0)
            LOOP
                v_message := 'Працівника з таким ід немає';
                raise_application_error(-20004, v_message);
            END LOOP search_employee;

        <<create_sql>>
        FOR c IN (SELECT col_name, col_val
                  FROM (SELECT column_name                              as col_name,
                               DECODE(LOWER(column_name),
                                      'first_name', p_first_name,
                                      'last_name', p_last_name,
                                      'email', p_email,
                                      'phone_number', p_phone_number,
                                      'job_id', p_job_id,
                                      'salary', p_salary,
                                      'commission_pct', p_commission_pct,
                                      'manager_id', p_manager_id,
                                      'department_id', p_department_id) as col_val
                        FROM ALL_TAB_COLUMNS
                        WHERE OWNER = USER
                          AND TABLE_NAME = 'EMPLOYEES')
                  WHERE col_val IS NOT NULL )
            LOOP

                v_sql_part :=
                        v_sql_part || CASE v_step WHEN 0 THEN '' ELSE ',' END
                            || c.col_name || '=''' || c.col_val || ''' ';
                v_step := v_step + 1;
            END LOOP create_sql;

        v_sql := 'UPDATE sergiyi_onu.employees SET ' || v_sql_part || ' WHERE employee_id = ' || p_employee_id;

        <<execute_sql>>
        BEGIN
            EXECUTE IMMEDIATE v_sql;
            v_message := 'У співробітника ' || p_employee_id || ' успішно оновлені атрибути';
            log_util.log_finish(p_proc_name => 'change_attribute_employee', p_text => v_message);

        EXCEPTION
            WHEN OTHERS THEN
                log_util.log_error(p_proc_name => 'change_attribute_employee', p_sqlerrm => SQLERRM);
                raise_application_error(-20001, 'При зміні атрибутів виникла помилка. Подробиці: ' || SQLERRM);
        END execute_sql;

    END change_attribute_employee;

    PROCEDURE copy_table(p_source_scheme IN VARCHAR2,
                         p_target_scheme IN VARCHAR2 DEFAULT USER,
                         p_list_table IN VARCHAR2,
                         p_copy_data IN BOOLEAN DEFAULT FALSE,
                         po_result OUT VARCHAR2,
                         p_auto_commit BOOLEAN DEFAULT FALSE) IS

        v_source_scheme VARCHAR2(50)  := UPPER(p_source_scheme);
        v_target_scheme VARCHAR2(50)  := UPPER(p_target_scheme);
        v_list_table    VARCHAR2(250) := UPPER(p_list_table);
        v_ddl_code      VARCHAR2(500);
        v_dml_code      VARCHAR2(500);
        v_step          NUMBER        := 0;
        v_count         NUMBER;
        v_message       VARCHAR2(250);

        PROCEDURE execute_ddl_code(p_sql IN VARCHAR2) IS
            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            EXECUTE IMMEDIATE p_sql;
        EXCEPTION
            WHEN OTHERS THEN
                log_util.log_error(p_proc_name => 'do_create_table', p_sqlerrm => SQLERRM,
                                   p_text => 'Помилка створення таблиці');
        END;

    BEGIN

        <<table_processing>>
        FOR c IN (
            SELECT table_name
            FROM all_tables
            WHERE OWNER = v_source_scheme
              and table_name in (select value_list
                                 from TABLE (util.TABLE_FROM_LIST(v_list_table))))
            LOOP

                v_ddl_code := 'CREATE TABLE ' || v_target_scheme || '.' || c.table_name || ' AS ' ||
                              'SELECT * FROM ' || v_source_scheme || '.' || c.table_name || ' WHERE 1 != 1';
                v_step := v_step + 1;

                <<ddl_execution>>
                BEGIN

                    SELECT COUNT(*)
                    INTO v_count
                    FROM all_tables
                    WHERE owner = v_target_scheme
                      AND table_name = c.table_name;

                    IF v_count = 0 /*тобто таблиці не існує*/ THEN
                        execute_ddl_code(v_ddl_code);
                        v_message := 'Таблицю ' || c.table_name || ' скопійовано зі схеми ' || v_source_scheme ||
                                     ' до схеми ' || v_target_scheme;
                        --|| '. Скопійовано ' || SQL%ROWCOUNT || ' рядків.';
                        to_log(p_appl_proc => 'util.copy_table', p_message => v_message);

                    ELSE
                        v_message := 'Таблиця ' || c.table_name || ' вже існує у схемі ' || v_target_scheme ||
                                     '. Копіювання не здійснюється.';
                        to_log(p_appl_proc => 'util.copy_table', p_message => v_message);
                    END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_message :=
                                'При копіюванні таблиці ' || c.table_name || ' виникла помилка. Подробиці: ' || SQLERRM;
                        to_log(p_appl_proc => 'util.copy_table', p_message => v_message);
                        CONTINUE;

                END ddl_execution;

                --перевіряємо, чи треба копіювати вміст таблиці
                IF p_copy_data THEN

                    v_dml_code := 'INSERT INTO ' || v_target_scheme || '.' || c.table_name ||
                                  'SELECT * FROM ' || v_source_scheme || '.' || c.table_name;

                    <<dml_execution>>
                    BEGIN
                        IF v_count = 0 /*тобто таблиці не існувало*/ THEN
                            EXECUTE IMMEDIATE v_dml_code;
                            v_message := 'До таблиці ' || v_target_scheme || '.' || c.table_name || ' скопійовано ' ||
                                         SQL%ROWCOUNT || ' рядків з таблиці ' || v_source_scheme || '.' || c.table_name;
                            to_log(p_appl_proc => 'util.copy_table', p_message => v_message);

                        ELSE
                            v_message := 'Таблиця ' || c.table_name || ' вже існує у схемі ' || v_target_scheme ||
                                         '. Копіювання не здійснюється.';
                            to_log(p_appl_proc => 'util.copy_table', p_message => v_message);
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_message :=
                                    'При копіюванні даних до таблиці ' || c.table_name ||
                                    ' виникла помилка. Подробиці: ' || SQLERRM;
                            to_log(p_appl_proc => 'util.copy_table', p_message => v_message);
                            CONTINUE;

                    END dml_execution;

                END IF;

                log_util.log_finish(p_proc_name => 'util.copy_table');

            END LOOP table_processing;

        IF v_step = 0 THEN
            raise_application_error(-20001, 'Не знайдено жодної таблиці для копіювання');
        END IF;

        IF p_auto_commit THEN
            COMMIT;
        END IF;

        po_result := 'Процедуру завершено.';

    EXCEPTION
        WHEN OTHERS THEN
            po_result := 'Виникла помилка: ' || SQLERRM;
            to_log(p_appl_proc => 'util.copy_table', p_message => po_result);

    END copy_table;

END util;
/