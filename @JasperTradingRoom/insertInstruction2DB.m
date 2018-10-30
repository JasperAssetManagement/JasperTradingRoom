function insertInstruction2DB(tins,torder)
% ��ÿ�յ�ָ����Ϣ��ָ����ϸ���
% input:  
%   tins ָ����Ϣ������([Trade_dt],[Account],[ModelName],[InsParam],[Advisor],[Remark])
%        ��Ҫ��ȡ [InsID],[InsType]
%   torder ָ����ϸ������([Trade_dt],[Windcode],[Qty])
%          ��Ҫ��ȡ [InsID]           
% ��: JasperTradingRoom.insertInstruction2DB(tins,torder);
% by Neo - 2017.12.12 
%% ��ȡ InsID��InsType
jtr = JasperTradingRoom;
conn = jtr.db88conn;
sql = ['SELECT MAX(InsID) FROM [JasperDB].[dbo].[InstructionInfo] where trade_dt=''' tins.trade_dt{1} ''' and account=''' tins.account{1} ''';'];
rowdata = Utilities.getsqlrtn(conn,sql);
if strcmp(rowdata,'null')==1
    tins.insid=[tins.trade_dt{1} '01' tins.account{1}];
else
    tpid=cell2mat(rowdata);
    tins.insid=[tins.trade_dt{1} num2str(str2double(tpid(9:10))+1,'%02d') tins.account{1}];
    %cCnt = num2str(str2double(cell2mat(rowdata))+1,'%02d');   
end
if tins.insparam==0
    tins.instype='����';
elseif tins.insparam>0
    tins.instype='�Ӳ�';
else
    tins.instype='����';
end
conn=jtr.db88conn;
res = Utilities.upsert(conn,'JasperDB.dbo.InstructionInfo',tins.Properties.VariableNames,[1 1 0 0 0 0 0 1 0],table2cell(tins));  
fprintf('upsert InstructionInfo:insert %d,update %d \n',sum(res==1),sum(res==0));

torder.insid=repmat(tins.insid,size(torder,1),1);
conn=jtr.db88conn;
res = Utilities.upsert(conn,'JasperDB.dbo.InstructionDetail',torder.Properties.VariableNames,[1 1 0 1],table2cell(torder));  
fprintf('upsert InstructionDetail:insert %d,update %d \n',sum(res==1),sum(res==0));

end