--код для створення в'юшки звіту
create view rep_project_dep_v as
SELECT ext_fl.project_id
     , ext_fl.project_name
     , d.DEPARTMENT_NAME
     , count(e.EMPLOYEE_ID)         as count_employees
     , count(distinct e.MANAGER_ID) as count_distinct_managers
     , sum(e.SALARY)                as total_salary

FROM EXTERNAL ( (
         project_id NUMBER,
         project_name VARCHAR2(100),
         department_id NUMBER )
         TYPE oracle_loader DEFAULT DIRECTORY FILES_FROM_SERVER
         ACCESS PARAMETERS ( records delimited BY newline
         nologfile
         nobadfile
         fields terminated BY ','
             missing field VALUES are NULL )
         LOCATION ('PROJECTS.csv')
         REJECT LIMIT UNLIMITED ) ext_fl

         join HR.DEPARTMENTS d using (department_id)
         join HR.EMPLOYEES e using (department_id)
group by ext_fl.project_id, ext_fl.project_name, d.DEPARTMENT_NAME
order by ext_fl.project_id

--PL-SQL блок для запису звіту у файл
declare
    file_handle   UTL_FILE.FILE_TYPE;
    file_location VARCHAR2(200) := 'FILES_FROM_SERVER';
    file_name     VARCHAR2(200) := 'TOTAL_PROJ_INDEX_TSO.csv'; -- Ім'я файлу, який буде записаний
    file_content  VARCHAR2(4000); -- Вміст файлу
BEGIN

    --додамо назви стовпчиків
    file_content := 'PROJECT_ID,PROJECT_NAME,DEPARTMENT_NAME,COUNT_EMPLOYEES,COUNT_DISTINCT_MANAGERS,TOTAL_SALARY' || CHR(10);
    -- Отримати вміст файлу з бази даних
    FOR cc IN (SELECT PROJECT_ID || ',' || PROJECT_NAME || ',' || DEPARTMENT_NAME || ',' || COUNT_EMPLOYEES || ',' || COUNT_DISTINCT_MANAGERS || ',' || TOTAL_SALARY AS file_content
               FROM SERGIYI_ONU.rep_project_dep_v)
        LOOP
            file_content := file_content || cc.file_content || CHR(10);
        END LOOP;

    -- Відкрити файл для запису
    file_handle := UTL_FILE.FOPEN(file_location, file_name, 'W');

-- Записати вміст файлу в файл на диск
    UTL_FILE.PUT_RAW(file_handle, UTL_RAW.CAST_TO_RAW(file_content));

    -- Закрити файл
    UTL_FILE.FCLOSE(file_handle);

EXCEPTION
    WHEN OTHERS THEN
        RAISE;

END;
/