function importZFOrders(s_date)
%每日导入ZF模型的交易单
% input：日期，支持yyyymmdd类型和日期类型
% 如果没有输入，则默认为today
jtr = JasperTradingRoom;

if ( nargin == 0 )
    s_date=datestr(today(),'yyyymmdd');
elseif isnumeric(s_date)
    s_date=datestr(s_date,'yyyymmdd');    
end
s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
%清除已生成模型指令
conn=jtr.db88conn;
sql=['delete from [JasperDB].[dbo].[JasperZFOrders] where [Date]=''' s_date ''';'];
Utilities.execsql(conn,sql);

% modelMap = getModelInfo();
inputValue={};
sDir=dir(['\\192.168.1.85\ZForders\model portfolio\*' s_ydate '.csv']);
for i=1:length(sDir)
    rowdata=Utilities.csvimport(['\\192.168.1.85\ZForders\model portfolio\' sDir(i).name]);
   
    tpc = rowdata(2:end-1,:);
    tpc(:,3)={s_date};
    tpc(:,4)=cellfun(@(x) {str2double(x)},tpc(:,4));
    tIdx=strfind(sDir(i).name,'.');
    tpc(:,end+1) = {sDir(i).name((tIdx(1)+1):(tIdx(2)-1))};
    tpc(:,end+1) = {sDir(i).name(6:(tIdx(1)-1))};
    
    inputValue(size(inputValue,1)+1:size(inputValue,1)+size(tpc,1),:) = tpc;
end

conn = jtr.db88conn;
res = Utilities.upsert(conn,'JasperDB.dbo.JasperZFOrders',{'Symbol','BarraId','Date','Weight','Strategy','Account'},[1 0 1 0 1 1],inputValue);  
fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));  

end
%配置需要导入的文件
% function modelMap = getModelInfo()
% modelMap = containers.Map({'BAL','ZF502','ZF35','ZF300'},{'balance','ZZ500_2','HS300&ZZ500','HS300'});  
% end
