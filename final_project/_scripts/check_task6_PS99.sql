--�������� ������� sys_params
SELECT *
FROM sergiyi_onu.sys_params;

--�������� ������� cur_exchange
SELECT *
FROM sergiyi_onu.cur_exchange;

--������ ������ ���������
BEGIN
    sergiyi_onu.util.api_nbu_sync();
END;
/

--�������� ���������� ������
SELECT *
FROM all_scheduler_jobs;

--�������� �����
BEGIN
    dbms_scheduler.disable(name=>'SYNC_CURRENCIES_JOB', force => TRUE);
END;
/