function [] = CalDailyPositionPL(s_date,account,mergeAccount,f_updateDB,f_calHKDiffDay,w)
%% calculate the position pnl
jtr = JasperTradingRoom;
if 0==f_calHKDiffDay
    s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'), -1, 'outputStyle','yyyymmdd');
else
    s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),-1,'market','HK','outputStyle','yyyymmdd');
end
%获取香港的最近T,T-1交易日
% hks_date=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');
% hks_ydate=Utilities.tradingdate(datenum(s_ydate,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');

excludedPosList={'IH1908.CFE'};

%导入收盘后数据    
[pos,trade]=getDBInfo(s_date,s_ydate,jtr);    
[stockPct,fundPct,hkPct,fuPct,forexPct,optionPct] = getQuotaInfo(s_date); %bondPct,ctaPct,

    
if 0==f_calHKDiffDay
    %s_date2=Utilities.tradingdate(today,-2,'outputStyle','yyyymmdd');
    [liusd, cusf]=getExtenalMarketInfo(s_date,s_ydate, w); 
    %w_data=[2.069,2.3416];
    dateDiff=Utilities.calDateDiff(s_ydate,s_date); %calculate the natural date diff 
else
    liusd=[];
    cusf=[];
    dateDiff=0;    
end

%计算position pnl
if ~Utilities.isTradingDates(s_date, 'SZ')
    if Utilities.isTradingDates(s_date, 'HK')
        pos=pos(strcmp(pos.type,'HKS')==1,:);
    else
        return
    end
end
%不计算未上市新股
conn=jtr.dbWindconn;
sql=['SELECT S_IPO_PURCHASECODE+RIGHT(S_INFO_WINDCODE,3) FROM [dbo].[ASHAREIPO] where S_IPO_LISTDATE>''' s_ydate ''''];
ipoList=Utilities.getsqlrtn(conn,sql);
[isin,~]=ismember(pos.symbol,ipoList);
pos=pos(isin==0,:);
%排除一些特殊标的
[isin,~]=ismember(pos.symbol,excludedPosList);
pos=pos(isin==0,:);

tmpL=unique(account.id);
[isin,~]=ismember(pos.account,tmpL);
[posPnl]=calPositionPnl(account,pos(isin==1,:),stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,liusd,dateDiff,cusf,s_date); %bondPct,ctaPct,

%计算trading pnl
if ~isempty(trade)
    [isin,~]=ismember(trade.account,tmpL);
    [tradingPnl]=calTradingPnl(account,trade(isin==1,:),stockPct,fundPct,hkPct,fuPct,forexPct,optionPct);   
end

%入库
if exist('tradingPnl','var')
    posPnl=outerjoin(posPnl,tradingPnl,'MergeKeys',true);
    posPnl=fillmissing(posPnl,'constant',0,'DataVariables',@isnumeric);
end
sumCol=posPnl.Properties.VariableNames(2:end);
sumCol(strcmp(sumCol,'FuPosPnlClose')==1)=[];
sumCol(strcmp(sumCol,'SpecialFee')==1)=[];
posPnl.TotalReturn=sum(posPnl{:,sumCol},2);
posPnl.Trade_dt=repmat({s_date},size(posPnl,1),1);

%合并账户
if ~isempty(mergeAccount)
    tmpKey=mergeAccount.keys;
    for i_acc=1:length(tmpKey)
        tmpT=table(tmpKey(i_acc),{s_date},'VariableNames',{'Account','Trade_dt'});
        sub_accL=mergeAccount(tmpKey{i_acc});
        [isin,~]=ismember(sub_accL,tmpL);
        if sum(isin)>0            
            sub_accL=sub_accL(isin);
            tmpA=zeros(1, size(posPnl,2)-2);
            for i_sub=1:length(sub_accL)
                tmpA=tmpA+table2array(posPnl(strcmp(posPnl.Account,sub_accL{i_sub})==1,2:end-1));
            end
            tmpT=[tmpT array2table(tmpA,'VariableNames',posPnl.Properties.VariableNames(2:end-1))];
            posPnl=[posPnl;tmpT];
        end
    end
end

%计算申购公司产品的产品, type=OTC
otcpos=pos(strcmp(pos.type,'OTC')==1,:);
if ~isempty(otcpos)
    conn=jtr.db88conn;
    sql='select Account, Windcode from [dbo].[OTCMap];';
    otcmap=Utilities.getsqlrtn(conn,sql);
    [isin,rows]=ismember(otcmap.Account,posPnl.Account);
    fprintf('Error(%s): Main-(%s) is not is otc map. \n',datestr(now(),0),join(otcmap{isin==0,'Windcode'}));
    otcpct=posPnl(rows(isin==1),{'Account','TotalReturn'});
    otcpct=join(otcpct,otcmap,'MergeKeys',True);
    otcpct.Properties.VariableNames('TotalReturn')={'change_price'};
    posPnl=calOTCPnl(account,otcpos,otcpct,posPnl);
end

if 1==f_updateDB        
    conn=jtr.db88conn;
    res = upsert(conn,'JasperDB.dbo.AccountDetail',posPnl.Properties.VariableNames,{'Trade_dt','Account'},table2cell(posPnl));     

    fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
end

end

function [pos,trade] = getDBInfo(s_date,s_ydate,jtr)
%导入收盘后数据     
    [pos]=getPosition(s_ydate,jtr);     
    [trade]=getTradeInfo(s_date,jtr);
end

function [stockPct,fundPct,hkPct,fuPct,forexPct,optionPct] = getQuotaInfo(s_date) %bondPct,ctaPct,
    root_path='\\192.168.1.88\Trading Share\daily_quote\';
    if Utilities.isTradingDates(s_date, 'HK') 
        hkPct=readtable([root_path 'hkstock_' s_date '.csv']);
    else
        hkPct=table;
    end
    if Utilities.isTradingDates(s_date, 'SZ') 
        stockPct=readtable([root_path 'stock_' s_date '.csv']);
        fundPct=readtable([root_path 'fund_' s_date '.csv']);
        fuPct=readtable([root_path 'future_' s_date '.csv']);
    %     bondPct=readtable([root_path 'bond_' s_date '.csv']);
    %     ctaPct=readtable([root_path 'cta_' s_date '.csv']);   
        forexPct=readtable([root_path 'forex_' s_date '.csv']);
        optionPct=readtable([root_path 'option_' s_date '.csv']);
    else
        stockPct=table;
        fundPct=table;
        fuPct=table;        
        optionPct=table;
        s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'), 0, 'outputStyle','yyyymmdd');
        forexPct=readtable([root_path 'forex_' s_ydate '.csv']);
    end
end

%取出各账户持仓
function [pos] = getPosition(s_ydate,jtr)
fprintf('Info(%s): getPosition-get (%s) Pos record. \n',datestr(now(),0),s_ydate);
    conn = jtr.db88conn;
    sqlstr=strcat('SELECT [Account],[WindCode],(1.5-[side])*2*[Qty] as Qty,[Type]',32,...
        'FROM [JasperDB].[dbo].[JasperPositionNew] where Trade_dt=''',s_ydate,''' order by account;');
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        fprintf('getPosition Error(%s): %s Position has not found in DB. \n',datestr(now(),0),s_ydate);       
    else
        pos=cell2table(data,'VariableNames',{'account' 'symbol' 'volume' 'type'});      
    end 
end

%取出交易数据
function [trade]=getTradeInfo(s_date,jtr)
fprintf('Info(%s): getTradeInfo-get (%s) Trade record. \n',datestr(now(),0),s_date);
    conn = jtr.db88conn;
    sqlstr=strcat('SELECT [Account],[WindCode],qty*(1.5-side)*2,[Type],Price,OCtag',32,...
        'FROM [JasperDB].[dbo].[JasperTradeDetail] where Trade_dt=''',s_date,''' order by account;'); 
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        fprintf('getTradeInfo Error(%s): %s Trade record has not found in DB. \n',datestr(now(),0),s_date);
        trade=table;
    else
        trade=cell2table(data,'VariableNames',{'account' 'symbol' 'volume' 'type' 'price' 'tag'}); 
    end
end

function [multiplier] = getMultiplier(type,symbol)
type=upper(type);
if strcmp(type,'FU')==1
    if strcmp(symbol{1}(1:2),'IC')==1
        multiplier=200;
    else
        multiplier=300;
    end
elseif strcmp(type,'OPTION')==1
    multiplier=10000;
else
    multiplier=1;
end
end

function []=checkRecords(pos, pct)
[isin,~]=ismember(pos.symbol, pct.symbol);
if find(isin==0)>0
    fprintf('Symbol do not included in pct files! \n');
    fprintf('%s \n',pos.symbol{isin==0});
end
end

%----------------------------------------------------------------%
function [posPnl]=calPositionPnl(account,pos,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,liusd,dateDiff,cusf,s_date)
fprintf('Info(%s):calPositionPnl-getMultiplier! \n',datestr(now(),0));
tmp_t=rowfun(@getMultiplier,pos,'InputVariables',{'type','symbol'},'OutputVariableNames','multiplier');
pos=[pos tmp_t];
%处理股票
if Utilities.isTradingDates(s_date, 'SZ')     
    stock=pos(strcmp(pos.type,'S')==1,:);    
    future=pos(strcmp(pos.type,'FU')==1,:);
    fund=pos(strcmp(pos.type,'F')==1,:);
    option=pos(strcmp(pos.type,'Option')==1,:);
    
    if ~isempty(stock)
        fprintf('Info(%s):calPositionPnl-Deal stock Records! \n',datestr(now(),0));
        checkRecords(stock, stockPct);  
        stock=join(stock,stockPct,'Keys','symbol');  
        stock.posPnl=stock.change_price.*stock.volume_stock; 
        stockPosPnl=varfun(@sum,stock,'InputVariables','posPnl','GroupingVariables','account');    
        stockPosPnl.GroupCount=[];    
        stockPosPnl.Properties.VariableNames={'Account','StockPosPnl'};
    else
        stockPosPnl=table;
    end
    
    if ~isempty(future)
        fprintf('Info(%s):calPositionPnl-Deal future Records! \n',datestr(now(),0));
        checkRecords(future, fuPct);  
        future=join(future,fuPct,'Keys','symbol');   
        future.posPnlClose=(future.close-future.pre_close).*future.volume_future.*future.multiplier;
        future.posPnlSettle=(future.settle-future.pre_settle).*future.volume_future.*future.multiplier;
        futurePosPnlClose=varfun(@sum,future,'InputVariables','posPnlClose','GroupingVariables','account');
        futurePosPnlSettle=varfun(@sum,future,'InputVariables','posPnlSettle','GroupingVariables','account');
        futurePosPnlClose.GroupCount=[];
        futurePosPnlSettle.GroupCount=[];
        futurePosPnlClose.Properties.VariableNames={'Account','FuPosPnlClose'};
        futurePosPnlSettle.Properties.VariableNames={'Account','FuPosPnlSettle'};
    else
        futurePosPnlClose=table;
        futurePosPnlSettle=table;
    end
    
    if ~isempty(fund)
        fprintf('Info(%s):calPositionPnl-Deal fund Records! \n',datestr(now(),0));
        checkRecords(fund, fundPct);
        fund=join(fund,fundPct,'Keys','symbol');
        fund.posPnl=fund.change_price.*fund.volume_fund;
        fundPosPnl=varfun(@sum,fund,'InputVariables','posPnl','GroupingVariables','account');
        fundPosPnl.GroupCount=[];
        fundPosPnl.Properties.VariableNames={'Account','FundPosPnl'};
    else
        fundPosPnl=table;
    end  
    
    if ~isempty(option)
        fprintf('Info(%s):calPositionPnl-Deal option Records! \n',datestr(now(),0));
        checkRecords(option, optionPct);    
        option=join(option,optionPct,'Keys','symbol');    
        fprintf('Info(%s):calPositionPnl-cal A share pnl! \n',datestr(now(),0));    
        option.posPnl=option.change_price.*option.volume_option.*option.multiplier; 
        optionPosPnl=varfun(@sum,option,'InputVariables','posPnl','GroupingVariables','account');
        optionPosPnl.GroupCount=[];
        optionPosPnl.Properties.VariableNames={'Account','OptionPosPnl'};
    else
        optionPosPnl=table;
    end
    
    % deal with the pos fee of HK account
    if ~isempty(stock(strcmp(stock.account,'86')==1,:)) || ~isempty(stock(strcmp(stock.account,'88')==1,:))
        fprintf('Info(%s):calPositionPnl-cal hk account special fee(stock)! \n',datestr(now(),0));
        tmp_pos=stock((strcmp(stock.account,'86')==1) | (strcmp(stock.account,'88')==1),:);    
        tmp_pos.SpecialFee=zeros(size(tmp_pos,1),1);
        tmp_pos.SpecialFee=abs(tmp_pos.close.*tmp_pos.volume_stock*(liusd(1)/100+0.009)/365*dateDiff);
        stockSpecialFee=varfun(@sum,tmp_pos,'InputVariables','SpecialFee','GroupingVariables','account');
        stockSpecialFee.GroupCount=[];
        stockSpecialFee.Properties.VariableNames={'Account','stockSpecialFee'};
    else
        stockSpecialFee=table([],[],'VariableNames',{'Account','stockSpecialFee'});
    end

    if ~isempty(fund(strcmp(fund.account,'86')==1,:)) || ~isempty(fund(strcmp(fund.account,'88')==1,:))
        fprintf('Info(%s):calPositionPnl-cal hk account special fee(fund)! \n',datestr(now(),0));
        tmp_pos=fund((strcmp(fund.account,'86')==1) | (strcmp(fund.account,'88')==1),:);
        tmp_pos.SpecialFee=zeros(size(tmp_pos,1),1);
        tmp_pos.SpecialFee=abs(tmp_pos.close.*tmp_pos.volume_fund*(0.045-liusd(2)/100)/365*dateDiff);
        fundSpecialFee=varfun(@sum,tmp_pos,'InputVariables','SpecialFee','GroupingVariables','account');
        fundSpecialFee.GroupCount=[];
        fundSpecialFee.Properties.VariableNames={'Account','fundSpecialFee'};
    else
        fundSpecialFee=table([],[],'VariableNames',{'Account','fundSpecialFee'});
    end

    % deal with the forex pnl
    if ~isempty(stock(strcmp(stock.account,'88')==1,:))
        fprintf('Info(%s):calPositionPnl-cal hk account forex pnl! \n',datestr(now(),0));
        posLongMV88=sum(stock.close(strcmp(stock.account,'88')==1).*stock.volume_stock(strcmp(stock.account,'88')==1));
        posShortMV88=sum(fund.close(strcmp(fund.account,'88')==1).*fund.volume_fund(strcmp(fund.account,'88')==1));
        forexPnl=-(posLongMV88+posShortMV88)*cusf;
        stockSpecialFee.stockSpecialFee(strcmp(stockSpecialFee.Account,'88')==1)=stockSpecialFee.stockSpecialFee(strcmp(stockSpecialFee.Account,'88')==1)+forexPnl;
    end

    specialFee=outerjoin(stockSpecialFee,fundSpecialFee,'MergeKeys',true);
    specialFee.SpecialFee=specialFee.stockSpecialFee+specialFee.fundSpecialFee;
    specialFee.SpecialFee(isnan(specialFee.SpecialFee))=0;
    specialFee.stockSpecialFee=[];
    specialFee.fundSpecialFee=[];    
else
    stockPosPnl=table;
    futurePosPnlClose=table;
    futurePosPnlSettle=table;
    fundPosPnl=table;
    optionPosPnl=table;
    specialFee=table;
end

if Utilities.isTradingDates(s_date, 'HK') 
    fprintf('Info(%s):calPositionPnl-cal HK share pnl! \n',datestr(now(),0));
    hkstock=pos(strcmp(pos.type,'HKS')==1,:);
    checkRecords(hkstock, hkPct);
    hkstock=join(hkstock,hkPct,'Keys','symbol');
    hkstock.posPnl=hkstock.change_price.*hkstock.volume_hkstock*forexPct.close(cellfun(@(x) contains(x,'HKDCNY'),forexPct.symbol));
    hkstockPosPnl=varfun(@sum,hkstock,'InputVariables','posPnl','GroupingVariables','account');
    hkstockPosPnl.GroupCount=[];
    hkstockPosPnl.Properties.VariableNames={'Account','HKPosPnl'}; 
else
    hkstockPosPnl=table;
end

 % merge
fprintf('Info(%s):calPositionPnl-merge A share classification detail into ONE table! \n',datestr(now(),0));
if ~isempty(stockPosPnl)
    posPnl=stockPosPnl;
    if ~isempty(hkstockPosPnl)
        posPnl=outerjoin(posPnl,hkstockPosPnl,'MergeKeys',true); 
    end
else
    if ~isempty(hkstockPosPnl)
        posPnl=hkstockPosPnl;
    end
end
if ~isempty(futurePosPnlClose)
    posPnl=outerjoin(posPnl,futurePosPnlClose,'MergeKeys',true);  
end
if ~isempty(futurePosPnlSettle)
    posPnl=outerjoin(posPnl,futurePosPnlSettle,'MergeKeys',true);
end
if ~isempty(fundPosPnl)
    posPnl=outerjoin(posPnl,fundPosPnl,'MergeKeys',true);
end
if ~isempty(optionPosPnl)
    posPnl=outerjoin(posPnl,optionPosPnl,'MergeKeys',true);
end
if ~isempty(specialFee)
    posPnl=outerjoin(posPnl,specialFee,'MergeKeys',true);    
else
    posPnl.SpecialFee=zeros(size(posPnl,1),1);
end 
posPnl=fillmissing(posPnl,'constant',0,'DataVariables',@isnumeric);
% [isin,~]=ismember('StockPosPnl',posPnl.Properties.VariableNames);
if contains('StockPosPnl',posPnl.Properties.VariableNames)
    posPnl.StockPosPnl=posPnl.StockPosPnl-posPnl.SpecialFee;
end
% cal pnl(bps)
fprintf('Info(%s):calPositionPnl-cal pnl(bps), divide capital! \n',datestr(now(),0));
tmpT=unique(account(:,{'id','capital'}));
posPnl=join(posPnl,tmpT,'LeftKeys','Account','RightKeys','id');
tmpPnl=varfun(@(x) x./posPnl.capital*10000,posPnl,'InputVariables',posPnl.Properties.VariableNames(2:end-1));
tmpPnl.Properties.VariableNames=posPnl.Properties.VariableNames(2:end-1);
posPnl=[posPnl(:,1),tmpPnl];
end

%----------------------------------------------------------------%
%计算trading pnl
function [tradePnl]=calTradingPnl(account,trade,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct)
fprintf('Info(%s):calTradingPnl-getMultiplier! \n',datestr(now(),0));
tmp_t=rowfun(@getMultiplier,trade,'InputVariables',{'type','symbol'},'OutputVariableNames','multiplier');
trade=[trade tmp_t];

stock=trade(strcmp(trade.type,'S')==1,:);
hkstock=trade(strcmp(trade.type,'HKS')==1,:);
future=trade(strcmp(trade.type,'FU')==1,:);
fund=trade(strcmp(trade.type,'F')==1,:);
option=trade(strcmp(trade.type,'Option')==1,:);

defaultFee=0.001;
    function [fee]=calFee(price, vol)
        if vol<0
            fee=abs(price*vol*defaultFee);
        else
            fee=0;
        end
    end

if ~isempty(stock)
    fprintf('Info(%s):calTradingPnl-deal stock records! \n',datestr(now(),0));
    checkRecords(stock, stockPct);
    stock=join(stock,stockPct,'Keys','symbol');
    stock.StockTradePnl=(stock.close-stock.price).*stock.volume_stock;
    stockFee=account(strcmp(account.sec_type,'STOCK')==1,{'id','commission','min_commission'});
    stockFee.Properties.VariableNames('commission')={'commission_rate'};
    stock=join(stock,stockFee,'LeftKeys','account','RightKeys','id');
    stock.commission=stock.price.*abs(stock.volume_stock).*stock.commission_rate;
    stock.commission=rowfun(@(x,y) max(x,y),stock,'InputVariables',{'commission','min_commission'},'OutputFormat','uniform');
    stock.fee=rowfun(@calFee,stock,'InputVariables',{'price','volume_stock'},'OutputFormat','uniform');
    stock.StockTradePnl=stock.StockTradePnl-stock.commission-stock.fee;
    stockTradePnl=varfun(@sum,stock,'InputVariables',{'StockTradePnl'},'GroupingVariables','account');
    stockTradePnl.GroupCount=[];  
    stockTradePnl.Properties.VariableNames={'Account','StockTradePnl'}; 
    stockFeePnl=varfun(@sum,stock,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    stockTradePnl=table([],[],'VariableNames',{'Account','StockTradePnl'});
end

if ~isempty(hkstock)
    fprintf('Info(%s):calTradingPnl-deal hk stock records! \n',datestr(now(),0));
    checkRecords(hkstock, hkPct);
    hkstock=join(hkstock,hkPct,'Keys','symbol');
    hkstock.HKTradePnl=(hkstock.close-hkstock.price).*hkstock.volume_hkstock*forexPct.close(strcmp(forexPct.symbol,'HKDCNY.EX')==1);
    hkstock=join(hkstock,stockFee,'LeftKeys','account','RightKeys','id');
    hkstock.commission=hkstock.price.*abs(hkstock.volume_hkstock).*hkstock.commission_rate*forexPct.close(strcmp(forexPct.symbol,'HKDCNY.EX')==1);
    hkstock.commission=rowfun(@(x,y) max(x,y),hkstock,'InputVariables',{'commission','min_commission'},'OutputFormat','uniform');
    hkstock.fee=rowfun(@calFee,hkstock,'InputVariables',{'price','volume_hkstock'},'OutputFormat','uniform');
    hkstock.HKTradePnl=hkstock.HKTradePnl-hkstock.commission-hkstock.fee;
    hkstockTradePnl=varfun(@sum,hkstock,'InputVariables',{'HKTradePnl'},'GroupingVariables','account');
    hkstockTradePnl.GroupCount=[];
    hkstockTradePnl.Properties.VariableNames={'Account','HKTradePnl'};
    hkstockFeePnl=varfun(@sum,hkstock,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    hkstockTradePnl=table([],[],'VariableNames',{'Account','HKTradePnl'});
end

if ~isempty(future)
    fprintf('Info(%s):calTradingPnl-deal future records! \n',datestr(now(),0));
    checkRecords(future, fuPct);
    future=join(future,fuPct,'Keys','symbol');
    future.FuTradePnlClose=(future.close-future.price).*future.volume_future.*future.multiplier;
    future.FuTradePnlSettle=(future.settle-future.price).*future.volume_future.*future.multiplier;
    futureFee=account(strcmp(account.sec_type,'FUTURE')==1,{'id','commission','min_commission'});
    futureFee.Properties.VariableNames('commission')={'commission_rate'};
    future=join(future,futureFee,'LeftKeys','account','RightKeys','id');
    future.commission=future.price.*abs(future.volume_future).*future.commission_rate.*future.multiplier + future.min_commission;
    future.fee=zeros(size(future,1),1);
    future.FuTradePnlClose=future.FuTradePnlClose-future.commission-future.fee;
    future.FuTradePnlSettle=future.FuTradePnlSettle-future.commission-future.fee;
    futureTradePnlClose=varfun(@sum,future,'InputVariables',{'FuTradePnlClose'},'GroupingVariables','account');
    futureTradePnlSettle=varfun(@sum,future,'InputVariables',{'FuTradePnlSettle'},'GroupingVariables','account');
    futureTradePnlClose.GroupCount=[];
    futureTradePnlSettle.GroupCount=[]; 
    futureTradePnlClose.Properties.VariableNames={'Account','FuTradePnlClose'}; 
    futureTradePnlSettle.Properties.VariableNames={'Account','FuTradePnlSettle'};
    futureFeePnl=varfun(@sum,future,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    futureTradePnlClose=table([],[],'VariableNames',{'Account','FuTradePnlClose'});
    futureTradePnlSettle=table([],[],'VariableNames',{'Account','FuTradePnlSettle'});
end

if ~isempty(fund)
    fprintf('Info(%s):calTradingPnl-deal fund records! \n',datestr(now(),0));
    checkRecords(fund, fundPct);
    fund=join(fund,fundPct,'Keys','symbol');
    fund.FundTradePnl=(fund.close-fund.price).*fund.volume_fund;
    fund=join(fund,stockFee,'LeftKeys','account','RightKeys','id');
    fund.commission=fund.price.*abs(fund.volume_fund).*fund.commission_rate;
    fund.commission=rowfun(@(x,y) max(x,y),fund,'InputVariables',{'commission','min_commission'},'OutputFormat','uniform');
    fund.fee=zeros(size(fund,1),1); % 暂时不计算fund的佣金
    fund.FundTradePnl=fund.FundTradePnl-fund.commission-fund.fee;
    fundTradePnl=varfun(@sum,fund,'InputVariables',{'FundTradePnl'},'GroupingVariables','account');
    fundTradePnl.GroupCount=[];
    fundTradePnl.Properties.VariableNames={'Account','FundTradePnl'}; 
    fundFeePnl=varfun(@sum,fund,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    fundTradePnl=table([],[],'VariableNames',{'Account','FundTradePnl'});
end

    function optionCom=calOptCom(vol, octag, commission_rate)
        if (vol<0) && (strcmp(octag,'open')==1)
            optionCom=0;
        else
            optionCom=abs(vol*commission_rate);
        end
    end
if ~isempty(option)
    fprintf('Info(%s):calTradingPnl-deal option records! \n',datestr(now(),0));
    checkRecords(option, optionPct);
    option=join(option,optionPct,'Keys','symbol');
    option.OptionTradePnl=(option.close-option.price).*option.volume_option.*option.multiplier;
    optionFee=account(strcmp(account.sec_type,'OPTION')==1,{'id','commission','min_commission'});
    optionFee.Properties.VariableNames('commission')={'commission_rate'};
    option=join(option,optionFee,'LeftKeys','account','RightKeys','id');    
    option.commission=rowfun(@calOptCom,option,'InputVariables',{'volume_option','tag','commission_rate'},'OutputFormat','uniform');
    option.fee=zeros(size(option,1),1); % 暂时不计算fund的佣金
    option.OptionTradePnl=option.OptionTradePnl-option.commission-option.fee;
    optionTradePnl=varfun(@sum,option,'InputVariables',{'OptionTradePnl'},'GroupingVariables','account');
    optionTradePnl.GroupCount=[];
    optionTradePnl.Properties.VariableNames={'Account','OptionTradePnl'}; 
    optionFeePnl=varfun(@sum,option,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    optionTradePnl=table([],[],'VariableNames',{'Account','OptionTradePnl'});
end

% 根据账号汇总
fprintf('Info(%s):calTradingPnl-sum pnl! \n',datestr(now(),0));
tradePnl=stockTradePnl;
if ~isempty(hkstockTradePnl)
    tradePnl=outerjoin(tradePnl,hkstockTradePnl,'MergeKeys',true); 
end
if ~isempty(futureTradePnlClose)
    tradePnl=outerjoin(tradePnl,futureTradePnlClose,'MergeKeys',true);   
    tradePnl=outerjoin(tradePnl,futureTradePnlSettle,'MergeKeys',true);  
end
if ~isempty(fundTradePnl)
    tradePnl=outerjoin(tradePnl,fundTradePnl,'MergeKeys',true); 
end
if ~isempty(optionTradePnl)
    tradePnl=outerjoin(tradePnl,optionTradePnl,'MergeKeys',true); 
end
tradePnl=fillmissing(tradePnl,'constant',0,'DataVariables',@isnumeric); 

% cal pnl(bps)
fprintf('Info(%s):calTradingPnl-cal pnl(bps), divide capital! \n',datestr(now(),0));
tmpT=unique(account(:,{'id','capital'}));
tradePnl=join(tradePnl,tmpT,'LeftKeys','Account','RightKeys','id');
tmpPnl=varfun(@(x) x./tradePnl.capital*10000,tradePnl,'InputVariables',tradePnl.Properties.VariableNames(2:end-1));
tmpPnl.Properties.VariableNames=tradePnl.Properties.VariableNames(2:end-1);
tradePnl=[tradePnl(:,1),tmpPnl];
end

%----------------------------------------------------------------%
function [posPnl]=calOTCPnl(account,pos,otcmap,posPnl)
fprintf('Info(%s):calOTCPnl-deal otc records! \n',datestr(now(),0));
pos=join(pos,otcmap,'MergeKeys',true);
pos.posPnl=pos.change_price.*pos.volume; 
OTCPosPnl=varfun(@sum,pos,'InputVariables','posPnl','GroupingVariables','Account');    
OTCPosPnl.GroupCount=[];    
OTCPosPnl.Properties.VariableNames={'Account','OTCPosPnl'};
posPnl=outerjoin(posPnl,OTCPosPnl,'MergeKeys',true);
posPnl=fillmissing(posPnl,'constant',0,'DataVariables',@isnumeric);
% cal pnl(bps)
fprintf('Info(%s):calOTCPnl-add pnl(bps) 2 total Pnl, divide capital! \n',datestr(now(),0));
tmpT=unique(account(:,{'id','capital'}));
posPnl=join(posPnl,tmpT,'LeftKeys','Account','RightKeys','id');
posPnl.OTCPosPnl=posPnl.OTCPosPnl./posPnl.capital;
posPnl.TotalReturn=posPnl.TotalReturn+posPnl.OTCPosPnl;
end

function [liusd, cusf] = getExtenalMarketInfo(tdate,tydate, w)    
    s_date=Utilities.tradingdate(datenum(tdate,'yyyymmdd'),-1,'outputStyle','yyyymmdd'); 
    tpd=w.wsd('LIUSD1M.IR,LIUSD3M.IR','close',s_date,s_date); 
    while ~isnumeric(tpd)
        s_date=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),-1,'outputStyle','yyyymmdd'); 
        tpd=w.wsd('LIUSD1M.IR,LIUSD3M.IR','close',s_date,s_date); 
    end
    liusd = tpd;
    
    cusf=w.wsd('USDCNY.EX','close',tdate,tdate)/w.wsd('USDCNY.EX','close',tydate,tydate)-1;    
end
