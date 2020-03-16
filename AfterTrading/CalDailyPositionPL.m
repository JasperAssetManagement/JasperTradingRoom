function [] = CalDailyPositionPL(s_date,account,mergeAccount,f_updateDB,f_calHKDiffDay,excludedPosList)
%% calculate the position pnl
jtr = JasperTradingRoom;
s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'), -1, 'outputStyle','yyyymmdd');

%获取香港的最近T,T-1交易日
% hks_date=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');
% hks_ydate=Utilities.tradingdate(datenum(s_ydate,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');

%导入收盘后数据    
[pos,trade,pos_margin,cash_pos_margin]=getDBInfo(s_date,s_ydate,jtr);    
[stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,cashPct,sc_member] = getQuotaInfo(s_date,s_ydate); %bondPct,ctaPct,

    
if 0==f_calHKDiffDay
    %s_date2=Utilities.tradingdate(today,-2,'outputStyle','yyyymmdd');
    [liusd, cusf]=getExtenalMarketInfo(s_date); 
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
pos=pos(isin==1,:);
[posPnl]=calPositionPnl(account,pos,pos_margin,cash_pos_margin,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,cashPct,liusd,dateDiff,cusf,s_date); %bondPct,ctaPct,

%计算trading pnl
if ~isempty(trade)
    [isin,~]=ismember(trade.account,tmpL);
    trade=trade(isin==1,:);
    [tradingPnl]=calTradingPnl(account,trade,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,sc_member);   
end

%入库
if exist('tradingPnl','var')
    posPnl=outerjoin(posPnl,tradingPnl,'MergeKeys',true);
    posPnl=fillmissing(posPnl,'constant',0,'DataVariables',@isnumeric);
end
sumCol=posPnl.Properties.VariableNames(2:end);
sumCol(strcmp(sumCol,'FuPosPnlClose')==1)=[];
sumCol(strcmp(sumCol,'FuTradePnlClose')==1)=[];
sumCol(strcmp(sumCol,'SpecialFee')==1)=[];
sumCol(strcmp(sumCol,'MarginInterest')==1)=[];
posPnl.TotalReturn=sum(posPnl{:,sumCol},2);
posPnl.Trade_dt=repmat({s_date},size(posPnl,1),1);

% 先合并80，为了计算80的feeder的净值
klist = {'80'};
for i=1:length(klist)
    tmpT=table(klist(i),{s_date},'VariableNames',{'Account','Trade_dt'});
    sub=mergeAccount(klist{i});
    [isin,~]=ismember(sub,tmpL);
    if sum(isin)>0            
        sub=sub(isin);
        tmpA=zeros(1, size(posPnl,2)-2);
        for i_sub=1:length(sub)
            if ~isempty(find(strcmp(posPnl.Account,sub{i_sub})==1, 1))
                tmpA=tmpA+table2array(posPnl(strcmp(posPnl.Account,sub{i_sub})==1,2:end-1));
            end
        end
        tmpT=[tmpT array2table(tmpA,'VariableNames',posPnl.Properties.VariableNames(2:end-1))];
    end
end

%计算申购公司产品的产品, type=OTC
otcpos=pos(strcmp(pos.type,'OTC')==1,:);
if ~isempty(otcpos)
    conn=jtr.db88conn;
    sql='select Account, Windcode from [dbo].[OTCMap];';
    rowdata=Utilities.getsqlrtn(conn,sql);
    otcmap=cell2table(rowdata,'VariableNames',{'Account','Windcode'});
    [isin,rows]=ismember(otcmap.Account,tmpT.Account);
    if sum(isin)==0
        fprintf('Error(%s): Main-(%s) is not in otc map. \n',datestr(now(),0),join(otcmap{isin==0,'Windcode'}));
    else
        otcpct=tmpT(rows(isin==1),{'Account','TotalReturn'});
        otcpct=join(otcpct,otcmap,'Keys','Account');
        otcpct.Properties.VariableNames('TotalReturn')={'change_price'};
        otcpct.Properties.VariableNames('Windcode')={'symbol'};
        posPnl=calOTCPnl(account,otcpos,otcpct,posPnl);
    end
end

%合并账户
if ~isempty(mergeAccount)
    tmpKey=mergeAccount.keys;
    for i_acc=1:length(tmpKey)
        tmpT=table(tmpKey(i_acc),{s_date},'VariableNames',{'Account','Trade_dt'});
        variables=posPnl.Properties.VariableNames;
        variables(strcmp(variables,'Trade_dt')==1)=[];
        variables(strcmp(variables,'Account')==1)=[];
        sub_accL=mergeAccount(tmpKey{i_acc});
        [isin,~]=ismember(sub_accL,tmpL);
        if sum(isin)>0            
            sub_accL=sub_accL(isin);
            tmpA=zeros(1, size(posPnl,2)-2);
            for i_sub=1:length(sub_accL)
                if ~isempty(find(strcmp(posPnl.Account,sub_accL{i_sub})==1, 1))
                    tmpA=tmpA+table2array(posPnl(strcmp(posPnl.Account,sub_accL{i_sub})==1,variables));
                end
            end
            tmpT=[tmpT array2table(tmpA,'VariableNames',variables)];
            posPnl=[posPnl;tmpT];
        end
    end
end
if 1==f_updateDB        
    conn=jtr.db88conn;
    res = upsert(conn,'JasperDB.dbo.AccountDetail',posPnl.Properties.VariableNames,{'Trade_dt','Account'},table2cell(posPnl));     

    fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
end

end

function [pos,trade,pos_margin,cash_pos_margin] = getDBInfo(s_date,s_ydate,jtr)
%导入收盘后数据     
    [pos]=getPosition(s_ydate,jtr);     
    [trade]=getTradeInfo(s_date,jtr);
    [pos_margin]=getMarginPos(s_date,jtr);
    if ~isempty(pos_margin)
        cash_pos_margin=pos(ismember(pos.account, unique(pos_margin.account))&strcmp(pos.type, 'C')==1,:);    
    else
        cash_pos_margin=table;
    end
end

function [stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,cashPct,sc_member] = getQuotaInfo(s_date,s_ydate) %bondPct,ctaPct,
    root_path='\\192.168.1.88\Trading Share\daily_quote\';
%     if Utilities.isTradingDates(s_date, 'HK') 
    hkPct=readtable([root_path 'hkstock_' s_date '.csv']);
%     else
%         hkPct=table;
%     end
    if Utilities.isTradingDates(s_date, 'SZ') 
        stockPct=readtable([root_path 'stock_' s_date '.csv']);
        fundPct=readtable([root_path 'fund_' s_date '.csv']);
        fuPct=readtable([root_path 'future_' s_date '.csv']);
    %     bondPct=readtable([root_path 'bond_' s_date '.csv']);
        ctaPct=readtable([root_path 'cta_' s_date '.csv']);   
        forexPct=readtable([root_path 'forex_' s_date '.csv']);
        optionPct=readtable([root_path 'option_' s_date '.csv']);
        cashPct=readtable([root_path 'cash_' s_date '.csv']);
        sc_member=readtable(['\\192.168.1.135\prod\research\avail_short\shsz_sc_members\' s_ydate '.shsz_sc_members.csv']);
    else
        stockPct=table;
        fundPct=table;
        fuPct=table;        
        optionPct=table;
        cashPct=table;
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
    sqlstr=strcat('SELECT [Account],[WindCode],qty*(1.5-side)*2,[Type],Price,OCtag,isnull(commission,0) as commission,isnull(fee,0) as fee',32,...
        'FROM [JasperDB].[dbo].[JasperTradeDetail] where Trade_dt=''',s_date,''' order by account;'); 
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        fprintf('getTradeInfo Error(%s): %s Trade record has not found in DB. \n',datestr(now(),0),s_date);
        trade=table;
    else
        trade=cell2table(data,'VariableNames',{'account' 'symbol' 'volume' 'type' 'price' 'tag' 'commission' 'fee'}); 
    end
end

% get margin call pos to calculate fee
function [pos_margin]=getMarginPos(s_date, jtr)
fprintf('Info(%s): getMarginPos-get (%s) Margin position. \n',datestr(now(),0),s_date);
    conn = jtr.db88conn;
    sqlstr = ['SELECT Account, WindCode, BorrowQty, Type FROM [dbo].[JasperBorrowRecords] where trade_dt = ''' s_date ''''];
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        fprintf('getMarginPos Info(%s): %s Margin position has not found in DB. \n',datestr(now(),0),s_date);
        pos_margin=table;
    else
        pos_margin=cell2table(data,'VariableNames',{'account' 'symbol' 'volume' 'type'}); 
    end
end

function [multiplier] = getMultiplier(type,symbol)
if strcmpi(type,'FU')==1
    if strcmpi(symbol{1}(1:2),'IC')==1
        multiplier=200;
    else
        multiplier=300;
    end
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
function [posPnl]=calPositionPnl(account,pos,pos_margin,cash_pos_margin,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,cashPct,liusd,dateDiff,cusf,s_date)
fprintf('Info(%s):calPositionPnl-getMultiplier! \n',datestr(now(),0));

%处理股票
if Utilities.isTradingDates(s_date, 'SZ')     
    stock=pos(strcmp(pos.type,'S')==1,:);    
    future=pos(strcmp(pos.type,'FU')==1,:);
    fund=pos(strcmp(pos.type,'F')==1,:);
    option=pos(strcmp(pos.type,'Option')==1,:);
    cta=pos(strcmp(pos.type,'CTA')==1,:);
    
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
        tmp_t=rowfun(@getMultiplier,future,'InputVariables',{'type','symbol'},'OutputVariableNames','multiplier');
        future=[future tmp_t];    
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
        option.posPnl=option.change_price.*option.volume_option.*option.multiplier; 
        optionPosPnl=varfun(@sum,option,'InputVariables','posPnl','GroupingVariables','account');
        optionPosPnl.GroupCount=[];
        optionPosPnl.Properties.VariableNames={'Account','OptionPosPnl'};
    else
        optionPosPnl=table;
    end
    
    if ~isempty(cta)
        fprintf('Info(%s):calPositionPnl-Deal cta Records! \n',datestr(now(),0));
        checkRecords(cta, ctaPct);    
        cta=join(cta,ctaPct,'Keys','symbol');    
        cta.posPnl=cta.change_price.*cta.volume_cta.*cta.multiplier; 
        ctaPosPnl=varfun(@sum,cta,'InputVariables','posPnl','GroupingVariables','account');
        ctaPosPnl.GroupCount=[];
        ctaPosPnl.Properties.VariableNames={'Account','CtaPosPnl'};
    else
        ctaPosPnl=table;
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
    
    if ~isempty(fund(strcmp(fund.account,'96')==1,:))      
        tmp_pos=fund(strcmp(fund.account,'96')==1,:);
        tmp_pos.SpecialFee=zeros(size(tmp_pos,1),1);
        tmp_pos.SpecialFee=abs(tmp_pos.close.*tmp_pos.volume_fund*0.09/365*dateDiff);
        tempSpecialFee=varfun(@sum,tmp_pos,'InputVariables','SpecialFee','GroupingVariables','account');
        tempSpecialFee.GroupCount=[];
        tempSpecialFee.Properties.VariableNames={'Account','fundSpecialFee'};
        fundSpecialFee = [fundSpecialFee;tempSpecialFee];
    end

    % deal with the forex pnl
    if ~isempty(stock(strcmp(stock.account,'88')==1,:))
        fprintf('Info(%s):calPositionPnl-cal hk account forex pnl! \n',datestr(now(),0));
        posLongMV88=sum(stock.close(strcmp(stock.account,'88')==1).*stock.volume_stock(strcmp(stock.account,'88')==1));
        posShortMV88=sum(fund.close(strcmp(fund.account,'88')==1).*fund.volume_fund(strcmp(fund.account,'88')==1));
        forexPnl=-(posLongMV88+posShortMV88)*cusf;
        stockSpecialFee.stockSpecialFee(strcmp(stockSpecialFee.Account,'88')==1)=stockSpecialFee.stockSpecialFee(strcmp(stockSpecialFee.Account,'88')==1)+forexPnl;
    end
    
    % cal margin call fee   
    if ~isempty(pos_margin)
        marginFee=account(strcmp(account.sec_type,'MARGIN')==1,{'id','commission','min_commission'});
        marginFee.Properties.VariableNames('commission')={'commission_rate'};
        checkRecords(cash_pos_margin,cashPct)
        pos_margin.account=rowfun(@(x) marginFee.id(contains(x, marginFee.id)),pos_margin,'InputVariables',{'account'},'OutputFormat','uniform');
        pos_margin=join(pos_margin,marginFee,'LeftKeys','account','RightKeys','id');        
%         pos_margin.commission_rate=rowfun(@(x) marginFee.commission_rate(contains(x, marginFee.id)),pos_margin,'InputVariables',{'account'},'OutputFormat','uniform');
        pos_margin_s=pos_margin(strcmp(pos_margin.type,'S')==1,:);
        pos_margin_s=join(pos_margin_s,stockPct,'Keys','symbol');  
        pos_margin_s.stockMarginSpecialFee=pos_margin_s.volume_pos_margin_s.*pos_margin_s.close.*pos_margin_s.commission_rate/250;
        pos_marginSpecialFee=varfun(@sum,pos_margin_s,'InputVariables','stockMarginSpecialFee','GroupingVariables','account');
        pos_marginSpecialFee.GroupCount=[];
        pos_marginSpecialFee.Properties.VariableNames={'Account','stockMarginSpecialFee'};
        
        pos_margin_f=pos_margin(strcmp(pos_margin.type,'F')==1,:);
        if ~isempty(pos_margin_f)
            pos_margin_f=join(pos_margin_f,fundPct,'Keys','symbol'); 
            pos_margin_f.fundMarginSpecialFee=pos_margin_f.volume_pos_margin_f.*pos_margin_f.close.*pos_margin_f.commission_rate/250; 
            tmp_f_fee=varfun(@sum,pos_margin_f,'InputVariables','fundMarginSpecialFee','GroupingVariables','account');
            tmp_f_fee.GroupCount=[];
            tmp_f_fee.Properties.VariableNames={'Account','fundMarginSpecialFee'};
            pos_marginSpecialFee=outerjoin(pos_marginSpecialFee,tmp_f_fee,'MergeKeys',true);
            pos_marginSpecialFee=fillmissing(pos_marginSpecialFee,'constant',0,'DataVariables',@isnumeric);
        else
            pos_marginSpecialFee.fundMarginSpecialFee=0;
        end
        
        if ~isempty(cash_pos_margin)
            cash_pos_margin.account=rowfun(@(x) marginFee.id(contains(x, marginFee.id)),cash_pos_margin,'InputVariables',{'account'},'OutputFormat','uniform');
            cash_pos_margin=join(cash_pos_margin,cashPct,'Keys','symbol');
            cash_pos_margin.interest=cash_pos_margin.volume.*cash_pos_margin.mmf_annualizedyield/250;    
            tmp_interest=varfun(@sum,cash_pos_margin,'InputVariables','interest','GroupingVariables','account');
            tmp_interest.GroupCount=[];
            tmp_interest.Properties.VariableNames={'Account','interest'};
            pos_marginSpecialFee=outerjoin(pos_marginSpecialFee,tmp_interest,'MergeKeys',true);
            pos_marginSpecialFee=fillmissing(pos_marginSpecialFee,'constant',0,'DataVariables',@isnumeric);    
        else
            pos_marginSpecialFee.interest=0;
        end
        
        pos_marginSpecialFee.pos_marginSpecialFee=pos_marginSpecialFee.stockMarginSpecialFee+pos_marginSpecialFee.fundMarginSpecialFee-pos_marginSpecialFee.interest;
        pos_marginSpecialFee.stockMarginSpecialFee=[];
        pos_marginSpecialFee.fundMarginSpecialFee=[];
        pos_marginSpecialFee.interest=[];
    end        
    
    specialFee=outerjoin(stockSpecialFee,fundSpecialFee,'MergeKeys',true);
    specialFee=fillmissing(specialFee,'constant',0,'DataVariables',@isnumeric);   
    specialFee.SpecialFee=specialFee.stockSpecialFee+specialFee.fundSpecialFee;
    specialFee.stockSpecialFee=[];
    specialFee.fundSpecialFee=[];  
    if ~isempty(pos_marginSpecialFee)
        specialFee=outerjoin(specialFee,pos_marginSpecialFee,'MergeKeys',true);
        specialFee=fillmissing(specialFee,'constant',0,'DataVariables',@isnumeric); 
        specialFee.SpecialFee=specialFee.SpecialFee+specialFee.pos_marginSpecialFee;        
        specialFee.pos_marginSpecialFee=[];
    end
    specialFee.SpecialFee(isnan(specialFee.SpecialFee))=0;
    
else
    stockPosPnl=table;
    futurePosPnlClose=table;
    futurePosPnlSettle=table;
    fundPosPnl=table;
    optionPosPnl=table;
    specialFee=table;
end

% if Utilities.isTradingDates(s_date, 'HK') 
fprintf('Info(%s):calPositionPnl-cal HK share pnl! \n',datestr(now(),0));
hkstock=pos(strcmp(pos.type,'HKS')==1,:);
if ~isempty(hkstock)
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
if ~isempty(ctaPosPnl)
    posPnl=outerjoin(posPnl,ctaPosPnl,'MergeKeys',true);  
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
posPnl.Properties.VariableNames('SpecialFee')={'MarginInterest'};
posPnl=[posPnl(:,1),tmpPnl,posPnl(:,'MarginInterest')];
end

%----------------------------------------------------------------%
%计算trading pnl
function [tradePnl]=calTradingPnl(account,trade,stockPct,fundPct,hkPct,fuPct,forexPct,optionPct,ctaPct,sc_member)
fprintf('Info(%s):calTradingPnl-getMultiplier! \n',datestr(now(),0));

stock=trade(strcmp(trade.type,'S')==1,:);
hkstock=trade(strcmp(trade.type,'HKS')==1,:);
future=trade(strcmp(trade.type,'FU')==1,:);
fund=trade(strcmp(trade.type,'F')==1,:);
option=trade(strcmp(trade.type,'Option')==1,:);
cta=trade(strcmp(trade.type,'CTA')==1,:);

defaultFee=0.001;
    function [fee]=calFee(price, vol)
        if vol<0
            fee=abs(price*vol*defaultFee);
        else
            fee=0;
        end
    end

    stockFee=account(strcmp(account.sec_type,'STOCK')==1,{'id','commission','min_commission'});
    stockFee.Properties.VariableNames('commission')={'commission_rate'};
    
if ~isempty(stock)
    fprintf('Info(%s):calTradingPnl-deal stock records! \n',datestr(now(),0));
    checkRecords(stock, stockPct);
    stock=join(stock,stockPct,'Keys','symbol');
    stock.StockTradePnl=(stock.close-stock.price).*stock.volume_stock; 
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
    hkstock.HKTradePnl=(hkstock.close-hkstock.price).*hkstock.volume_hkstock*forexPct.close(cellfun(@(x) contains(x,'HKDCNY'),forexPct.symbol));
    hkstock=join(hkstock,stockFee,'LeftKeys','account','RightKeys','id');
    hkstock.commission=hkstock.price.*abs(hkstock.volume_hkstock).*hkstock.commission_rate*forexPct.close(cellfun(@(x) contains(x,'HKDCNY'),forexPct.symbol));
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
    tmp_t=rowfun(@getMultiplier,future,'InputVariables',{'type','symbol'},'OutputVariableNames','multiplier');
    future=[future tmp_t];
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
    option.fee=zeros(size(option,1),1);
    option.OptionTradePnl=option.OptionTradePnl-option.commission-option.fee;
    optionTradePnl=varfun(@sum,option,'InputVariables',{'OptionTradePnl'},'GroupingVariables','account');
    optionTradePnl.GroupCount=[];
    optionTradePnl.Properties.VariableNames={'Account','OptionTradePnl'}; 
    optionFeePnl=varfun(@sum,option,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    optionTradePnl=table([],[],'VariableNames',{'Account','OptionTradePnl'});
end

if ~isempty(cta)
    fprintf('Info(%s):calTradingPnl-deal cta records! \n',datestr(now(),0));
    checkRecords(cta, ctaPct);
    cta=join(cta,ctaPct,'Keys','symbol');
    cta.CtaTradePnl=(cta.settle-cta.price).*cta.volume_cta.*cta.multiplier;    
    cta.CtaTradePnl=cta.CtaTradePnl-cta.commission-cta.fee;
    ctaTradePnl=varfun(@sum,cta,'InputVariables',{'CtaTradePnl'},'GroupingVariables','account');
    ctaTradePnl.GroupCount=[];
    ctaTradePnl.Properties.VariableNames={'Account','CtaTradePnl'}; 
    ctaFeePnl=varfun(@sum,option,'InputVariables',{'commission','fee'},'GroupingVariables','account');
else
    ctaTradePnl=table([],[],'VariableNames',{'Account','CtaTradePnl'});
end

 % deal with the sc member
if ~isempty(stock(strcmp(stock.account,'96')==1,:))
    fprintf('Info(%s):calTradingPnl-deal different commission rate of sc members! \n',datestr(now(),0));    
    tp_trade=stock(strcmp(stock.account,'96')==1,:);
    [isin,~]=ismember(tp_trade.symbol,sc_member.symbol);
    qfii_trade=tp_trade(~isin,:);
    qfiiFee=account{strcmp(account.id,'96')==1 & strcmp(account.sec_type,'QFII')==1,'commission'};
    scFee=account{strcmp(account.id,'96')==1 & strcmp(account.sec_type,'STOCK')==1,'commission'};
    qfiiTradeMv=qfii_trade.volume_stock.*qfii_trade.price;
    qfiiFeePlus=sum(qfiiTradeMv)*(qfiiFee-scFee);
    stockTradePnl(strcmp(stockTradePnl.Account,'96')==1,'StockTradePnl')={stockTradePnl{strcmp(stockTradePnl.Account,'96')==1,'StockTradePnl'}-qfiiFeePlus};
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
if ~isempty(ctaTradePnl)
    tradePnl=outerjoin(tradePnl,ctaTradePnl,'MergeKeys',true); 
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
pos=join(pos,otcmap,'Keys','symbol');
pos.posPnl=pos.change_price.*pos.volume/10000; 
pos.Account=[];    
OTCPosPnl=varfun(@sum,pos,'InputVariables','posPnl','GroupingVariables','account');    
OTCPosPnl.GroupCount=[];    
OTCPosPnl.Properties.VariableNames={'Account','OTCPosPnl'};
posPnl=outerjoin(posPnl,OTCPosPnl,'MergeKeys',true);
posPnl=fillmissing(posPnl,'constant',0,'DataVariables',@isnumeric);
% cal pnl(bps)
fprintf('Info(%s):calOTCPnl-add pnl(bps) 2 total Pnl, divide capital! \n',datestr(now(),0));
tmpT=unique(account(:,{'id','capital'}));
posPnl=join(posPnl,tmpT,'LeftKeys','Account','RightKeys','id');
posPnl.OTCPosPnl=posPnl.OTCPosPnl./posPnl.capital*10000;
posPnl.TotalReturn=posPnl.TotalReturn+posPnl.OTCPosPnl;
posPnl.capital=[];
end

function [liusd, cusf] = getExtenalMarketInfo(tdate)    
%     s_date=Utilities.tradingdate(datenum(tdate,'yyyymmdd'),-1,'outputStyle','yyyymmdd'); 
%     tpd=w.wsd('LIUSD1M.IR,LIUSD3M.IR','close',s_date,s_date); 
%     while ~isnumeric(tpd)
%         s_date=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),-1,'outputStyle','yyyymmdd'); 
%         tpd=w.wsd('LIUSD1M.IR,LIUSD3M.IR','close',s_date,s_date); 
%     end
%     liusd = tpd;
%     
%     cusf=w.wsd('USDCNY.EX','close',tdate,tdate)/w.wsd('USDCNY.EX','close',tydate,tydate)-1; 
root_path = '\\192.168.1.88\Trading Share\daily_quote\';
tpt = readtable([root_path 'forex_' tdate '.csv']);
liusd = tpt.pre_close(cellfun(@(x) contains(x,'LIUSD'),tpt.symbol));
cusf = tpt.pct_chg(cellfun(@(x) contains(x,'USDCNY'),tpt.symbol));
end
