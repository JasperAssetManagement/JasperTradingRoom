function [ ] = CalDailyTradeEffiency( date )
% CALDAILYTRADEEFFIENCY 
% 分别计算date，每个账户的相对于vwap(10分钟/20分钟)的trading pnl
% 输入:   date - 数值型或者是字符型（"yyyymmdd"）
% 输出:   无，直接更新到数据库中 AccountDetail.vwap10/vwap20
jtr = JasperTradingRoom;

if (nargin == 0)
    date = datestr(today(),'yyyymmdd');
elseif (nargin == 1 && isnumeric(date))
    date = datestr(date,'yyyymmdd');
end

%清除已生成持仓
conn=jtr.db88conn;
sql=['delete from [JasperDB].[dbo].[DailyTradeVwapDetail] where Trade_dt=''' date ''';'];
Utilities.execsql(conn,sql);

% 从数据库中去data日的成交明细，并进行归档处理 
trade = gettrade(date,jtr);

% 导入date的市场数据
marketinfo = getmarketinfo(date);

% 定义每个时间段的前一/后一区间
prev=containers.Map({'0930','0940','0950','1000','1010','1020','1030','1040','1050','1100','1110','1120','1130','1300','1310','1320','1330','1340','1350','1400','1410','1420','1430','1440','1450'}, ...
    {'0925','0930','0940','0950','1000','1010','1020','1030','1040','1050','1100','1110','1120','1130','1300','1310','1320','1330','1340','1350','1400','1410','1420','1430','1440'});
next=containers.Map({'0930','0940','0950','1000','1010','1020','1030','1040','1050','1100','1110','1120','1130','1300','1310','1320','1330','1340','1350','1400','1410','1420','1430','1440','1450'}, ...
    {'0940','0950','1000','1010','1020','1030','1040','1050','1100','1110','1120','1130','1300','1310','1320','1330','1340','1350','1400','1410','1420','1430','1440','1450','1450'});
tpa = arrayfun(@(x,y) marketinfo.(['vwap_' trade.category{y}]){strcmp(marketinfo.symbol,x)==1},trade.windcode,(1:size(trade.category))','un',0);
trade.vwap10_price = cellfun(@str2double,tpa);
trade.vwap20_price = zeros(size(trade,1),1);
for i=1:size(trade,1)
    pre=prev(trade.category{i});
    nxt=next(trade.category{i});
    row=find(strcmp(trade.windcode(i),marketinfo.symbol)==1);
    trade.vwap20_price(i) = (str2double(marketinfo.(['tot_amount_' pre]){row})+str2double(marketinfo.(['tot_amount_' nxt]){row})) / ...
        (str2double(marketinfo.(['tot_volume_' pre]){row})+str2double(marketinfo.(['tot_volume_' nxt]){row}));   
end

trade.vwap10 = trade.side.*(1-trade.price./trade.vwap10_price).*trade.ratio*10000;
trade.vwap20 = trade.side.*(1-trade.price./trade.vwap20_price).*trade.ratio*10000;

accDetail=varfun(@sum,trade,'InputVariables',{'vwap10','vwap20'},'GroupingVariables',{'account'});
accDetail.trade_dt=repmat({date},size(accDetail,1),1);
accDetail.GroupCount=[];
accDetail.Properties.VariableNames('sum_vwap10')={'vwap10'};
accDetail.Properties.VariableNames('sum_vwap20')={'vwap20'};

conn=jtr.db88conn;
res = upsert(conn,'JasperDB.dbo.AccountDetail',accDetail.Properties.VariableNames,[1 0 0 1],table2cell(accDetail));     
fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));

trade.sum_qty=trade.sum_qty.*trade.side;
trade.side=[];
trade.trade_dt=repmat({date},size(trade,1),1);

conn=jtr.db88conn;
res = upsert(conn,'JasperDB.dbo.DailyTradeVwapDetail',trade.Properties.VariableNames,[1 1 1 0 0 0 0 0 0 0 0 0 1],table2cell(trade));     
fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));

end

function trade = gettrade(date, jtr)
conn=jtr.db88conn;
sql=['SELECT [Account],[WindCode],[Qty],case when [Side]=1 then 1 else -1 end,qty*price,left([ExecuteTime],2)+SUBSTRING(ExecuteTime,4,2) ' ...
    'FROM [JasperDB].[dbo].[JasperTradeDetail] where [Type]=''S'' and Trade_dt=''' date ''' order by account;']; %and windcode != ''002601.SZ'' 
cdate=Utilities.getsqlrtn(conn,sql);
trade=cell2table(cdate,'VariableNames',{'account','windcode','qty','side','amount','ctime'});
trade.dtime=cellfun(@str2double,trade.ctime);
trade.category=cellstr(num2str(floor(trade.dtime/10)*10,'%04d'));
trade.category(strcmp(trade.category,'1500')==1)={'1450'};
trade=varfun(@sum,trade,'InputVariables',{'qty','amount'},'GroupingVariables',{'account','windcode','category','side'});%group by 'account','windcode','category','side'
trade.ratio=arrayfun(@(x,y) y/sum(trade.sum_amount(strcmp(trade.account,x)==1)),trade.account,trade.sum_amount);
trade.price=trade.sum_amount./trade.sum_qty;
end

function marketinfo = getmarketinfo( date )
rowdata=Utilities.csvimport(['\\192.168.1.75\ZForders\hf\' date '.10m_stats.csv']);
marketinfo=cell2table(rowdata(2:end,2:end));
marketinfo.Properties.VariableNames=rowdata(1,2:end);
end