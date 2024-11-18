SELECT *
FROM employees
;

BEGIN
    util.change_attribute_employee(109, 'John');
END;
/