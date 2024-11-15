--перевіримо таблицю логів
SELECT *
FROM logs
where trunc(LOG_DATE, 'DD') = trunc(sysdate, 'DD')
;

BEGIN
    --протестуємо із заповненим значенням p_text
    log_util.log_start(p_proc_name => 'test_start1', p_text => 'текст логу');
    log_util.log_finish(p_proc_name => 'test_finish1', p_text => 'текст логу');
    log_util.log_error(p_proc_name => 'test_error1', p_sqlerrm => 'текст помилки', p_text => 'текст логу');

    --протестуємо із пропущеним значенням p_text
    log_util.log_start(p_proc_name => 'test_start2');
    log_util.log_finish(p_proc_name => 'test_finish2');
    log_util.log_error(p_proc_name => 'test_error2', p_sqlerrm => 'текст помилки');
END;
/