create procedure del_jobs(p_job_id in varchar2,
                          po_result out varchar2) is
    v_check_job_id number;

begin

    select count(*)
    into v_check_job_id
    from SERGIYI_ONU.JOBS j
    where j.JOB_ID = p_job_id;

    if v_check_job_id = 0 then
        po_result := 'Посади ' || p_job_id || ' не існує';
    else
        delete from SERGIYI_ONU.JOBS j where j.JOB_ID = p_job_id;
        commit;
        po_result := 'Посада ' || p_job_id || ' успішно видалена';
    end if;

end del_jobs;
/