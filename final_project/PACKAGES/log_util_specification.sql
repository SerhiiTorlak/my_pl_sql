CREATE PACKAGE log_util AS

    PROCEDURE to_log(p_appl_proc IN VARCHAR2,
                     p_message IN VARCHAR2);

END log_util;
/