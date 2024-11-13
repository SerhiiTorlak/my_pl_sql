DECLARE
    v_year          NUMBER := 2012;
    v_check_year4   NUMBER;
    v_check_year100 NUMBER;
    v_check_year400 NUMBER;
BEGIN
    v_check_year4 := mod(v_year, 4);
    v_check_year100 := mod(v_year, 100);
    v_check_year400 := mod(v_year, 400);

    IF v_check_year400 = 0 THEN
        dbms_output.put_line(v_year || ' - високосний рік');
    ELSIF v_check_year100 = 0 THEN
        dbms_output.put_line(v_year || ' - не високосний рік');
    ELSIF v_check_year4 = 0 THEN
        dbms_output.put_line(v_year || ' - високосний рік');
    ELSE
        dbms_output.put_line(v_year || ' - не високосний рік');
    end if;
END;
/

--я дещо ускладнив умову відповідно з Григоріанським календарем:
--високосним є кожен 400й або 4й рік, окрім тих, що кратні 100, але не кратні 400
--тобто 2000 - високосний рік, а 1900 і 2100 - ні