function deleteInstruction(date,acctype, varargin)
%ɾ��������������µ�һ��ָ��/ָ����ϸ���¼
% input:
%   acctype 
%   1-ֻɾ��varargin����˻���varargin���˻�;
%   0-ʹ�ú�JasperTradingRoom.getAccInfoͬ����������ϵȡ�˺�
% ��: JasperTradingRoom.deleteInstruction(today(),1,{'13';'07'})
% ����JasperTradingRoom.deleteInstruction(today()-1,0,3)
% by Neo - 2017.12.13
jtr=JasperTradingRoom;
if isnumeric(date)
    date=datestr(date,'yyyymmdd');
end
switch acctype
    case 1
        accids=varargin{1};
    case 0
        accids=jtr.getAccInfo(varargin{1});
    otherwise
        warning('No defined account type!');
end

for i=1:size(accids,1)
    conn=jtr.db88conn;
    sql = ['SELECT MAX(InsID) FROM [JasperDB].[dbo].[InstructionInfo] where trade_dt=''' date ''' and account=''' accids{i} ''';'];
    rowdata = Utilities.getsqlrtn(conn,sql);
    if strcmp(rowdata,'null')==1
        warning('No instruction info found in DB. Account: %s!',accids{i});    
        continue;
    else
        insid=cell2mat(rowdata);    
    end
    
    conn=jtr.db88conn;
    sql=['delete from [JasperDB].[dbo].[InstructionInfo] where insid=''' insid ''' and trade_dt=''' date ''';' ...
        'delete from [JasperDB].[dbo].[InstructionDetail] where insid=''' insid ''' and trade_dt=''' date ''';'];
    Utilities.execsql(conn,sql);
    fprintf('Delete instruction done. Account: %s! \n',accids{i});
end

end