--процедура видалення посади
    procedure del_jobs(p_job_id in varchar2,
                       po_result out varchar2) is

        v_delete_no_data_found exception;

    begin

        check_work_time;

        begin

            delete from SERGIYI_ONU.JOBS j where j.JOB_ID = p_job_id;

            if SQL%ROWCOUNT = 0 then
                raise v_delete_no_data_found;
            end if;

        exception
            when v_delete_no_data_found then raise_application_error(-20004, 'Посади ' || p_job_id || ' не існує');

        end;

        po_result := 'Посада ' || p_job_id || ' успішно видалена';

    end del_jobs;