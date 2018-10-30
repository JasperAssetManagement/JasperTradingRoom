%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%函数名：DB2_ExcSQL
%功能：执行SQL语句，适用于DB2、SQL Server数据库
%输入参数：
%parameterSql——SQL语句（字符串格式）
%返回参数：
%data：cell数组
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ data ] = DBExcutor88( parameterSql )
%设置建立连接的最长时间，如果超过5秒内还未建立，则连接失败
timeoutA=logintimeout(5);

% 建立一个连接，其中RTDB为ODBC数据源名称，Administrator为用户名 112358为密码
%这个链接的是SQL server数据库
connA=database('JasperDB','sa','123.qwer','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://192.168.1.88:1433;databaseName=JasperDB');
%isconnection(connA) %若返回1则认为连接成功
% 检查数据库的状态


ping(connA);
% % 打开连接，执行sql语句
% cursorA=exec(connA,parameterSql);
% % 选择数据的前100行
% cursorA=fetch(cursorA,end)
% % 列出数据
% data=cursorA.Data;

data=fetch(connA,parameterSql);
% 关闭连接和数据库
%close(cursorA);
close(connA);
end

