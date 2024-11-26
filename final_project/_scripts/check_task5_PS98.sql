DECLARE
    v_result VARCHAR2(500);
BEGIN
    util.copy_table(p_source_scheme => 'hr',
                    --p_target_scheme => 'SERGIYI_ONU',
                    p_list_table => 'countries,locations',
                    --p_copy_data => TRUE,
                    po_result => v_result
    );
    dbms_output.put_line(v_result);
END;
/

DROP TABLE SERGIYI_ONU.countries;

SELECT *
FROM sergiyi_onu.logs
WHERE log_date > DATE '2024-11-18'
ORDER BY log_date DESC