function [ cData ] = getsqlrtn( conn, sql )
% 从数据库查询并获取返回数据
ping(conn);
curs = exec(conn,sql);
if isstruct(curs)
    error(['Error in DB Connection：',curs.Message]);
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

