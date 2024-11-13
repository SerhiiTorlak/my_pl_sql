CREATE or replace TRIGGER hire_date_update
    BEFORE UPDATE
    ON SERGIYI_ONU.EMPLOYEES
    FOR EACH ROW
DECLARE
    PRAGMA autonomous_transaction;
BEGIN

    IF :OLD.job_id != :NEW.job_id THEN

        :NEW.HIRE_DATE := TRUNC(SYSDATE, 'DD');

    END IF;

    commit;

END hire_date_update;
/