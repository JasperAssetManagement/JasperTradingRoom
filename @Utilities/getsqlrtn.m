function [ cData ] = getsqlrtn( conn, sql )
% �����ݿ��ѯ����ȡ��������
ping(conn);
curs = exec(conn,sql);
if isstruct(curs)
    error(['Error in DB Connection��',curs.Message]);
else
    curs = fetch(curs);
    cData = curs.Data;
    if strcmp(cData,'No Data')
        cData={};
        warning('No return data')
    end
end
close(conn);
end

