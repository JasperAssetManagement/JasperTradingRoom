function calVwapTradingPnlOfzfModel(timezone,startDate,endDate)
% 计算zf模型每日换仓的交易Pnl
% input：
%       timezone: 输入时间区间，采用vwap价格的时间段，如'0940'
% 例: JasperTradingRoom.calVwapTradingPnlOfzfModel('0940');
% 例: JasperTradingRoom.calVwapTradingPnlOfzfModel('1010','20171119');
%
% - by Neo 2018.01.08
jtr=JasperTradingRoom;
w=windmatlab;
if nargin==1
    startDate='20171123';
    endDate=datestr(today()-1,'yyyymmdd');
elseif nargin==2
    endDate=datestr(today()-1,'yyyymmdd');
end
caccDetail=cell(datenum(endDate,'yyyymmdd')-datenum(startDate,'yyyymmdd'),5);
i_a=1;
for i_d=datenum(startDate,'yyyymmdd'):datenum(endDate,'yyyymmdd')   
    %取出今日持仓
    conn=jtr.db88conn;   
    date=datestr(i_d,'yyyymmdd');
    sql=['SELECT [Symbol],[Weight],[Account] FROM [JasperDB].[dbo].[JasperZFOrders] where account in (''05'',''07'',''17'',''84'') and [date] = ''' date ... 
        ''' order by account,symbol;'];
    data=Utilities.getsqlrtn(conn,sql);
    if isempty(data)
        warning('%s do not have ZF model data!',datestr(i_d,'yyyymmdd'));
        continue
    end
    tbpos=cell2table(data,'VariableNames',{'symbol','weight','account'});
    %取出昨日持仓
    conn=jtr.db88conn;
    ydate=Utilities.tradingdate(i_d,-1,'outputStyle','yyyymmdd');
    sql=['SELECT [Symbol],[Weight],[Account] FROM [JasperDB].[dbo].[JasperZFOrders] where account in (''05'',''07'',''17'',''84'') and [date] = ''' ydate ... 
        ''' order by account,symbol;'];
    data=Utilities.getsqlrtn(conn,sql);
    if isempty(data)
        error('%s(yesterday) do not have ZF model data!',datestr(i_d,'yyyymmdd'));
    end
    tbypos=cell2table(data,'VariableNames',{'symbol','y_weight','account'});
    
    %轧差计算各账户两日的交易
    torders=outerjoin(tbpos,tbypos,'MergeKeys',1);
    torders.weight(isnan(torders.weight))=0;
    torders.y_weight(isnan(torders.y_weight))=0;
    torders.tradeweight=torders.weight-torders.y_weight;
    
    %去掉当日停牌的股票不计算
    code=unique(torders.symbol);
    cStatToday=w.wss(code,'trade_status',['tradeDate=' date]);
    status=arrayfun(@(x) cStatToday(strcmp(x,code)==1),torders.symbol);
    torders(~strcmp(status,'交易')==1,:)=[];   
    
    %获取当日的收盘价数据    
    closeprice=w.wsd(code,'close',date,date);  
    torders.closeprice=arrayfun(@(x) closeprice(strcmp(x,code)==1),torders.symbol);
    torders.closeprice(isnan(torders.closeprice))=0;
    
    %获取当日的vwap数据
    data=Utilities.csvimport(['V:\Neo\market\' date '.10m_stats.csv']);
    marketinfo=cell2table(data(2:end,2:end));
    marketinfo.Properties.VariableNames=data(1,2:end);
    tpa = arrayfun(@(x) marketinfo.(['vwap_' timezone]){strcmp(marketinfo.symbol,x)==1},torders.symbol,'un',0);
    torders.vwap10_price = cellfun(@str2double,tpa);
    
    %计算vwap2close的盈亏
    torders.tradingpnl=(1-torders.vwap10_price./torders.closeprice).*torders.tradeweight*10000;
    tpacc=varfun(@sum,torders,'InputVariables',{'tradingpnl'},'GroupingVariables',{'account'});
    caccDetail(i_a,:)=[{date},tpacc.sum_tradingpnl(1),tpacc.sum_tradingpnl(2),tpacc.sum_tradingpnl(3),tpacc.sum_tradingpnl(4)];    
    i_a=i_a+1;
end
w.close;
end