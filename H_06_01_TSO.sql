--створюємо таблицю, куди будемо зберігати результат
CREATE TABLE interbank_index_ua_history
(
    dt      DATE,
    id_api  VARCHAR2(50),
    value   NUMBER,
    special VARCHAR2(10)
);

--створюємо в'юшку і парсимо json
create view interbank_index_ua_v as
select to_date(tt.dt, 'dd.mm.yyyy') as dt
     , tt.id_api
     , tt.value
     , tt.special
from (select SYS.GET_NBU(p_url => 'https://bank.gov.ua/NBU_uonia?id_api=UONIA_UnsecLoansDepo&json') as res from dual) t
         cross join json_table
                    (
        res, '$[*]'
        COLUMNS
            (
            dt VARCHAR2(10) PATH '$.dt',
            id_api VARCHAR2(50) PATH '$.id_api',
            value NUMBER PATH '$.value',
            special VARCHAR2(10) PATH '$.special'
            )
                    ) tt;

--створюєме процедуру
create procedure download_ibank_index_ua as

begin
    insert into SERGIYI_ONU.INTERBANK_INDEX_UA_HISTORY
    select dt, id_api, value, special
    from interbank_index_ua_v;
end;
/

--процедура, яку включимо в scheduler
begin download_ibank_index_ua(); end;
/

--створюємо виконання процедури за розкладом
BEGIN
    sys.dbms_scheduler.create_job(job_name => 'download_ibank_index',
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => 'begin download_ibank_index_ua(); end;',
                                  start_date => SYSDATE,
                                  repeat_interval => 'FREQ=DAILY; BYHOUR=9; BYMINUTE = 0; BYSECOND=0',
                                  end_date => TO_DATE(NULL),
                                  job_class => 'DEFAULT_JOB_CLASS',
                                  enabled => TRUE,
                                  auto_drop => FALSE,
                                  comments => 'Зберігання даних з сайту НБУ');
END;
/