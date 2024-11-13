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