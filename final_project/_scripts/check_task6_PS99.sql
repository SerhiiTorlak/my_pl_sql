--перевірка таблиці sys_params
SELECT *
FROM sergiyi_onu.sys_params;

--перевірка таблиці cur_exchange
SELECT *
FROM sergiyi_onu.cur_exchange;

--ручний запуск процедури
BEGIN
    sergiyi_onu.util.api_nbu_sync();
END;
/

--перевірка створеного джобса
SELECT *
FROM all_scheduler_jobs;

--вимкнути джобс
BEGIN
    dbms_scheduler.disable(name=>'SYNC_CURRENCIES_JOB', force => TRUE);
END;
/

--перевіримо логи
SELECT *
FROM sergiyi_onu.logs
WHERE appl_proc = 'api_nbu_sync';