function importOtherOrders(date,model,acctype,secType, varargin)%
%% 导入基本面的成交指令（除了JZP）
% input：
%   date 日期，支持数值型和'yyyymmdd'型
%   model 模型名称
%   acctype 1 for JASON, 0 for All Accounts(Dox,Peter)
%           3 for ST,可在JasperTradingRoom.getAccInfo中定义
% 如果没有输入，则从昨天的记录拷贝一份
% 例：JasperTradingRoom.importOtherOrders(today(),'DOX',0,'S',[709 0.5; 959 0.5])
% 例：JasperTradingRoom.importOtherOrders
% by Neo - 2017/11
jtr=JasperTradingRoom;
if (nargin == 0)
    date=datestr(today(),'yyyymmdd');
elseif (nargin >= 1) && (isnumeric(date))
    date=datestr(date,'yyyymmdd');
end

%% 复制昨天的记录，[AvailableDays]=0
ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
conn=jtr.db88conn;
sql=['select ''' date ''',[WindCode],[Name],sum([Ratio]),[ModelName],0,[Advisor],[AccType] FROM [JasperDB].[dbo].[JasperOtherOrder] where Trade_dt=''' ,...
    ydate ''' group by [WindCode],[Name],[ModelName],[Advisor],[AccType] having sum([Ratio])>0;'];
rowdata=Utilities.getsqlrtn(conn,sql);
tpd=cell2table(rowdata,'VariableNames',{'trade_dt','windcode','name','ratio','modelname','availabledays','advisor','acctype'});
conn=jtr.db88conn;
res = Utilities.upsert(conn,'JasperDB.dbo.JasperOtherOrder',tpd.Properties.VariableNames,[1 1 0 0 1 1 0 1],table2cell(tpd));  
fprintf('upsert OtherOrder(from yest):insert %d,update %d \n',sum(res==1),sum(res==0));
      
if (nargin > 1)
    w=windmatlab;
    tab = cell2table(num2cell(varargin{1}),'VariableNames',{'windcode','ratio'});
    tab.windcode = Utilities.getStockWindCode(tab.windcode,secType);
    tab.ratio = tab.ratio/100;
    tab.name = w.wss(tab.windcode,'sec_name');
    tab.modelname = repmat({model},size(tab,1),1);
    tab.trade_dt = repmat({date},size(tab,1),1);
    tab.advisor = repmat({model},size(tab,1),1);
    tab.availabledays = repmat({1},size(tab,1),1);
    tab.acctype = repmat({acctype},size(tab,1),1);
    
    conn=jtr.db88conn;
    res = Utilities.upsert(conn,'JasperDB.dbo.JasperOtherOrder',tab.Properties.VariableNames,[1 0 0 1 1 0 1 0],table2cell(tab));  
    fprintf('upsert OtherOrder(from varargin):insert %d,update %d \n',sum(res==1),sum(res==0));    
    
    %同时更新到 OtherOrdersByQty
    tab.close=w.wsd(tab.windcode,'close',ydate,ydate);
    cTarAcc=jtr.getAccInfo(acctype);
    cAccs=jtr.getaccounts;
    [isin,rows]=ismember(cTarAcc,cAccs.ids);
    %dAccAssets=cAccs.AShareAmounts(rows(isin==1));       
    dAccAssets=cAccs.assets(rows(isin==1));       
    
    func=@(x,y) arrayfun(@(k,l,m,n,o) [y,k,l,round(x*m/n,-2),o],tab.windcode,tab.name,tab.ratio,tab.close,tab.modelname,'un',0);
    torder=arrayfun(func,dAccAssets,cTarAcc,'un',0);
   
    func=@(x) cat(1,x{:});
    torder=arrayfun(@(x) func(torder{x}),1:size(torder,1),'un',0);
    torder=cat(1,torder{:});
    
    torder=cell2table(torder,'VariableNames',{'account','windcode','name','qty','modelname'});
    torder.trade_dt=repmat({date},size(torder,1),1);
    torder.type=repmat({'S'},size(torder,1),1);
    torder.side=repmat({1},size(torder,1),1);
    
    conn=jtr.db88conn;
    res=Utilities.upsert(conn,'JasperDB.dbo.JasperOtherOrderByQty',torder.Properties.VariableNames,[1 1 0 0 1 1 0 0],table2cell(torder));
    fprintf('upsert OtherOrderByQty(from varargin):insert %d,update %d \n',sum(res==1),sum(res==0));   
    
    %同时更新到指令/指令明细表中
    accids=unique(torder.account);
    code=unique(torder.windcode);
    close=w.wsd(code,'close',ydate,ydate);
    torder.close=arrayfun(@(x) close(strcmp(x,code)==1),torder.windcode);
    for i=1:length(accids)
        rows=strcmp(accids(i),torder.account)==1;     
        cTrader=cAccs.traders(strcmp(cAccs.ids,accids(i))==1);
        tins=cell2table({date,accids{i},model,sum(torder.qty(rows).*torder.close(rows))/10000,model,cTrader,sum(torder.qty(rows).*torder.close(rows))/10000}, ...
            'VariableNames',{'trade_dt','account','modelname','insparam','advisor','remark','realinsparam'});
        tpt=torder(rows,{'windcode','qty','trade_dt'});       
        JasperTradingRoom.insertInstruction2DB(tins,tpt);
    end
    w.close;
end  

end
