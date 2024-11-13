DECLARE
    v_date DATE := TO_DATE('2024-07-03', 'YYYY-MM-DD');
    v_day  NUMBER;
BEGIN
    v_day := TO_NUMBER(TO_CHAR(v_date, 'DD'));

    IF v_date = LAST_DAY(v_date) THEN
        DBMS_OUTPUT.PUT_LINE('Виплата зарплати');
    ELSIF v_day = 15 THEN
        DBMS_OUTPUT.PUT_LINE('Виплата авансу');
    ELSIF v_day < 15 THEN
        DBMS_OUTPUT.PUT_LINE('Чекаємо на аванс');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Чекаємо на зарплату');
    END IF;

END;
/