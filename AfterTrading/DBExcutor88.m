%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%��������DB2_ExcSQL
%���ܣ�ִ��SQL��䣬������DB2��SQL Server���ݿ�
%���������
%parameterSql����SQL��䣨�ַ�����ʽ��
%���ز�����
%data��cell����
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ data ] = DBExcutor88( parameterSql )
%���ý������ӵ��ʱ�䣬�������5���ڻ�δ������������ʧ��
timeoutA=logintimeout(5);

% ����һ�����ӣ�����RTDBΪODBC����Դ���ƣ�AdministratorΪ�û��� 112358Ϊ����
%������ӵ���SQL server���ݿ�
connA=database('JasperDB','sa','123.qwer','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://192.168.1.88:1433;databaseName=JasperDB');
%isconnection(connA) %������1����Ϊ���ӳɹ�
% ������ݿ��״̬


ping(connA);
% % �����ӣ�ִ��sql���
% cursorA=exec(connA,parameterSql);
% % ѡ�����ݵ�ǰ100��
% cursorA=fetch(cursorA,end)
% % �г�����
% data=cursorA.Data;

data=fetch(connA,parameterSql);
% �ر����Ӻ����ݿ�
%close(cursorA);
close(connA);
end

