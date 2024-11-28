CREATE TRIGGER sergiyi_onu.employees_history
    AFTER DELETE
    ON sergiyi_onu.employees
    FOR EACH ROW
BEGIN
    INSERT INTO sergiyi_onu.employees_history (employee_id, first_name, last_name, email, phone_number, hire_date,
                                               fire_date, last_job_id, last_salary, last_manager_id, last_department_id)
    VALUES (:OLD.employee_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, :OLD.hire_date,
            TRUNC(SYSDATE, 'DD'), :OLD.job_id, :OLD.salary, :OLD.manager_id, :OLD.department_id);
END employees_history;