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
                           p_department_id IN NUMBER);

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
                EXIT WHEN l_cur%NOTFOUND; --��������� ������, ���� ����� �� ����������
                FETCH l_cur BULK COLLECT
                    INTO out_rec;
                FOR i IN 1 .. out_rec.count
                    LOOP
                        PIPE ROW (out_rec(i));
                    END LOOP;
            END LOOP;
            CLOSE l_cur; --��������� ������

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

        out_rec tab_value_list := tab_value_list(); --����������� �����
        l_cur   SYS_REFCURSOR;

    begin

        OPEN l_cur FOR
            SELECT TRIM(REGEXP_SUBSTR(p_list_val, '[^' || p_separator || ']+', 1, LEVEL)) AS cur_value
            FROM dual
            CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;

        BEGIN
            LOOP
                EXIT WHEN l_cur%NOTFOUND; --��������� ������, ���� ����� �� ����������
                FETCH l_cur BULK COLLECT
                    INTO out_rec;
                FOR i IN 1 .. out_rec.count
                    LOOP
                        PIPE ROW (out_rec(i));
                    END LOOP;
            END LOOP;
            CLOSE l_cur; --��������� ������

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
                EXIT WHEN l_cur%NOTFOUND; --��������� ������, ���� ����� �� ����������
                FETCH l_cur BULK COLLECT
                    INTO out_rec;
                FOR i IN 1 .. out_rec.count
                    LOOP
                        PIPE ROW (out_rec(i));
                    END LOOP;
            END LOOP;
            CLOSE l_cur; --��������� ������

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

--������� ��������� ����� ������ �� �� ����������
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

--����� ��������� ����� ������������ �� �� ����������
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
            v_message := '������������ �������! �������� ' || p_table || ' , � ��������� products ��� products_old';
            to_log(p_appl_proc => 'util.get_sum_price_sales', p_message => v_message);
            raise_application_error(-20001, v_message);
        END IF;

        v_sql_code := 'SELECT SUM(p.PRICE_SALES) from hr.' || p_table || ' p';

        EXECUTE IMMEDIATE v_sql_code INTO v_sum;

        RETURN v_sum;

    END get_sum_price_sales;

--��������� ��������, ���� ���� ������� - �������� �� �������
    FUNCTION check_work_time RETURN BOOLEAN IS

        v_check BOOLEAN;

    BEGIN
        IF to_char(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN') IN ('SAT', 'SUN')
            OR to_char(SYSDATE, 'HH24:MI') BETWEEN '18:01' AND '07:59' THEN
            v_check := FALSE;
        ELSE
            v_check := TRUE;
        END IF;

        RETURN v_check;

    END check_work_time;

--��������� ��������� ���� ������
    PROCEDURE add_new_job(p_job_id IN VARCHAR2,
                          p_job_title IN VARCHAR2,
                          p_min_salary IN NUMBER,
                          p_max_salary IN NUMBER DEFAULT NULL,
                          po_err OUT VARCHAR2) IS

        v_max_salary SERGIYI_ONU.JOBS.JOB_ID%TYPE;
        salary_err EXCEPTION;

    BEGIN

        IF NOT check_work_time THEN
            raise_application_error(-20205, '�� ������ ������� ���� ���� � ������ ��');
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
                po_err := '������ ' || p_job_id || ' ������ ������';
            END IF;

        EXCEPTION
            WHEN salary_err THEN raise_application_error(-20001, '�������� �������� ����� �� 2000');
            WHEN dup_val_on_index THEN raise_application_error(-20002, '������ ' || p_job_id || ' ��� ����');
            WHEN OTHERS THEN raise_application_error(-20003, '������� ������� ��� �������� ���� ������, ' || SQLERRM);

        END;

        --commit;

    END add_new_job;

--��������� ��������� ������
    PROCEDURE del_jobs(p_job_id IN VARCHAR2,
                       po_result OUT VARCHAR2) IS

        v_delete_no_data_found EXCEPTION;

    BEGIN

        IF NOT check_work_time THEN
            raise_application_error(-20205, '�� ������ ������� ���� ���� � ������ ��');
        END IF;

        BEGIN

            DELETE FROM SERGIYI_ONU.JOBS j WHERE j.JOB_ID = p_job_id;

            IF SQL%ROWCOUNT = 0 THEN
                RAISE v_delete_no_data_found;
            END IF;

        EXCEPTION
            WHEN v_delete_no_data_found THEN raise_application_error(-20004, '������ ' || p_job_id || ' �� ����');

        END;

        po_result := '������ ' || p_job_id || ' ������ ��������';

    END del_jobs;

--��������� � ��������� ������������ ��������� ����������
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
            FOR UPDATE; -- ������� ����� ��� ���������

        IF v_balance_old >= p_balance THEN
            UPDATE balance b
            SET b.balance = v_balance_old - p_balance
            WHERE employee_id = p_employee_id
            RETURNING b.balance INTO v_balance_new; -- ��� �� ������ ����� SELECT INTO
        ELSE
            v_message := 'Employee_id = ' || p_employee_id || '. ����������� ����� �� �������. �������� ������ ' ||
                         v_balance_old || ', ������ ������ ' || p_balance;
            raise_application_error(-20001, v_message);
        END IF;
        v_message := 'Employee_id = ' || p_employee_id || '. ����� ������ ���� � �������. ���� ' || v_balance_old ||
                     ', ����� ' || v_balance_new;

        dbms_output.put_line(v_message);

        to_log(p_appl_proc => 'util.update_balance', p_message => v_message);
        /*IF 1 = 0 THEN -- ������ ������������� �������
            v_message := '������������� �������';
            raise_application_error(-20001, v_message);
        END IF;*/
        COMMIT; -- �������� ����� ������ �� ������ ���������� � ������� ����������
    EXCEPTION
        WHEN OTHERS THEN
            to_log(p_appl_proc => 'util.update_balance',
                   p_message => NVL(v_message, 'Employee_id = ' || p_employee_id || '. ' || SQLERRM));
            ROLLBACK; -- ³������� ���������� � ��� ���������� �������
            raise_application_error(-20001, NVL(v_message, '������� �������'));
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
                              p_department_id IN NUMBER) IS

    v_message logs.message%TYPE;

BEGIN

    log_util.log_start(p_proc_name => 'add_employee');

    --��������� ��� ������� ������� ���
    IF NOT check_work_time() THEN
        v_message := '�� ������ �������� ������ ����������� ���� � ������� ���';
        raise_application_error(-20201, v_message);
    END IF;

    --����������, �� ���� ���������� job_id
    <<search_job_id>>
    FOR c IN (
        SELECT 1
        FROM jobs j
        WHERE j.job_id = p_job_id
        HAVING COUNT(*) = 0)
        LOOP
            v_message := '������� ��������� ��� ������';
            raise_application_error(-20002, v_message);
        END LOOP search_job_id;

    --����������, �� ���� ���������� department_id
    <<search_department_id>>
    FOR c IN (
        SELECT 1
        FROM departments d
        WHERE d.department_id = p_department_id
        HAVING COUNT(*) = 0)
        LOOP
            v_message := '������� ��������� ������������� �����';
            raise_application_error(-20003, v_message);
        END LOOP search_department_id;

    --���������� ��������
    <<search_salary>>
    FOR c IN (
        SELECT 1
        FROM jobs j
        WHERE p_salary BETWEEN j.min_salary AND j.max_salary
        HAVING COUNT(*) = 0)
        LOOP
            v_message := '������� ������������ �������� ����� ��� ������ ���� ������';
            raise_application_error(-20004, v_message);
        END LOOP search_salary;

    --insert new employee into the table
    <<insert_new_emp>>
    BEGIN
        INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary,
                               commission_pct, manager_id, department_id)
        VALUES (emp_seq.NEXTVAL, p_first_name, p_last_name, p_email, p_phone_number, p_hire_date, p_job_id, p_salary,
                p_commission_pct, p_manager_id, p_department_id);

        dbms_output.put_line('���������� ' || p_first_name || ' ' || p_last_name || ', ' || p_job_id || ', ' ||
                             p_department_id || ' ������ ������ �� �������');

    EXCEPTION
        WHEN OTHERS THEN log_util.log_error(p_proc_name => 'add_employee', p_sqlerrm => SQLERRM);
        RAISE;

    END insert_new_emp;

    log_util.log_finish(p_proc_name => 'add_employee');

END add_employee;

end util;
/

