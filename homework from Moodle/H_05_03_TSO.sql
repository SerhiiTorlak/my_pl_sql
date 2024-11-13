DECLARE
    v_recipient   VARCHAR2(50) ;
    v_employee_id NUMBER         := 207;
    v_subject     VARCHAR2(50)   := 'subject_task3';
    v_mes         VARCHAR2(5000) := 'Вітаю шановний! </br> Ось звіт з нашої компанії: </br></br>';
BEGIN

    select e.EMAIL || '@gmail.com'
    into v_recipient
    from SERGIYI_ONU.EMPLOYEES e
    where e.employee_id = v_employee_id;

    SELECT v_mes || '<!DOCTYPE html>
    <html>
        <head>
            <title></title>
            <style>
                table, th, td {border: 1px solid;}
                .center{text-align: center;}
            </style>
        </head>
        <body>
            <table border=1 cellspacing=0 cellpadding=2 rules=GROUPS frame=HSIDES>
                <thead>
                    <tr align=left>
                        <th>Ід департаменту</th>
                        <th>Кількість співробітників</th>
                    </tr>
                </thead>
                    <tbody>
                    ' || list_html || '
                    </tbody>
            </table>
        </body>
    </html>' AS html_table
    into v_mes
    FROM (SELECT LISTAGG('<tr align=left>
                <td>' || DEPARTMENT_ID || '</td>' || '
                <td class=''center''> ' || count_employees || '</td>
            </tr>', '<tr>')
                         WITHIN GROUP (ORDER BY DEPARTMENT_ID) AS list_html
          FROM (select DEPARTMENT_ID, count(EMPLOYEE_ID) as count_employees
                from SERGIYI_ONU.EMPLOYEES
                group by DEPARTMENT_ID));

    v_mes := v_mes || '</br></br> З повагою, Костя';
    sys.sendmail(p_recipient => v_recipient,
                 p_subject => v_subject,
                 p_message => v_mes || ' ');

END;
/