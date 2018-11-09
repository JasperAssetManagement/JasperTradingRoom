function [flag] = CalDailyPositionPL(s_date,s_ydate,stress,pctChg,closePrice,f_calPartOfAccounts,subAccounts,f_adjustCapitals,aCap,f_updateDB,w)
%% calculate the position pnl

%获取香港的最近T,T-1交易日
hks_date=Utilities.tradingdate(datenum(s_date,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');
hks_ydate=Utilities.tradingdate(datenum(s_ydate,'yyyymmdd'),0,'market','HK','outputStyle','yyyymmdd');
            
%benchmarkCode='H00300.CSI,H00905.CSI'; 
benchmarkCode='000300.SH,000905.SH'; 

[w_data]=w.wsd(benchmarkCode,'pct_chg',s_date,s_date);
benchmark.index1=w_data(1,1)/100; 
benchmark.index2=w_data(2,1)/100;
benchmark.ratio=0.3;
    
%导入收盘后数据    
[pos,trade,fuPos,account,model,flag] = getDBInfo(s_date,s_ydate,hks_date,hks_ydate,w);    
[fundPct,hkPct,ntbPct,bondPct]=getQuotaInfo(pos,trade,s_date,s_ydate,hks_date,hks_ydate,w);

   %计算个别账户
if 1==f_calPartOfAccounts
   [isin,rows]=ismember(subAccounts,account.ids);
   account.ids=account.ids(rows(isin==1));  
   account.capitals=account.capitals(rows(isin==1));
end 

   %如果赎回没有在AccountDetail里体现，这里改
if 1==f_adjustCapitals  
   [isin,rows]=ismember(aCap.accounts,account.ids); 
   if sum(isin==0)>0
       account.ids=[account.ids;aCap.accounts];
       account.capitals=[account.capitals;aCap.capitals];
   else
       account.capitals(rows(isin==1))=account.capitals(rows(isin==1))+aCap.capitals;
   end
end

    %计算模型的return,用来算P-U
    [isin,rows]=ismember(model.codes,pctChg.codes);
    model.return=mean(pctChg.pctchanges(rows(isin==1)));

    %计算position pnl
    %TODO: 取美股的最近一个交易日
%     s_date2=Utilities.tradingdate(today,-2,'outputStyle','yyyymmdd');
    [liusd, cusf]=getExtenalMarketInfo(s_date,s_ydate, w); 
    %w_data=[2.069,2.3416];
    dateDiff=Utilities.calDateDiff(s_ydate,s_date); %calculate the natural date diff 

    [posPnl]=calPositionPnl(account,pos,fuPos,pctChg,closePrice,hkPct,ntbPct,fundPct,bondPct,liusd,benchmark,dateDiff,cusf);
    
    %计算trading pnl
    [tradingPnl]=calTradingPnl(account,trade,fuPos,closePrice,hkPct,ntbPct,fundPct,bondPct);
    
    %计算定增股票池和10底层的Pnl
%     [posPnl] = addPIPEPnl(posPnl,account,tradingPnl,s_date);    
    %p-u
    p_u=posPnl.subReturn-model.return; 
    volData=[];
    posPnl.totalReturn=posPnl.stockPosPnl+posPnl.hkPosPnl+posPnl.neeqPosPnl+posPnl.fuPosPnlSettle+posPnl.fundPosPnl+tradingPnl.stockTradePnl+tradingPnl.hkTradePnl+tradingPnl.neeqTradePnl+tradingPnl.fuTradePnlSettle+tradingPnl.fundTradePnl;
    posPnl.totalReturn(isnan(posPnl.totalReturn))=0;  
    posPnl.stockPosPnl(isnan(posPnl.stockPosPnl))=0;
    s_dates=cell(size(account.ids,1),1);
    s_dates(:)={s_date};
    %volData=[volData; s_dates, account.ids, zeros(size(account.ids,1),4), {posPnl.totalReturn},{p_u},{alpha}];
    for i=1:size(account.ids,1)       
        volData=[volData; s_dates(i),account.ids(i),{posPnl.totalReturn(i)*10000},{1},{p_u(i)*10000},{stress},{'default'},{posPnl.alpha(i)*10000},... %%{0},{0},{0},{0},
            {posPnl.stockPosPnl(i)*10000},{posPnl.hkPosPnl(i)*10000},{posPnl.neeqPosPnl(i)*10000},{posPnl.fuPosPnlClose(i)*10000},{posPnl.fuPosPnlSettle(i)*10000},...
            {tradingPnl.stockTradePnl(i)*10000},{tradingPnl.hkTradePnl(i)*10000},{tradingPnl.neeqTradePnl(i)*10000},{tradingPnl.fuTradePnlClose(i)*10000},{tradingPnl.fuTradePnlSettle(i)*10000},...
            {posPnl.fundPosPnl(i)*10000},{tradingPnl.fundTradePnl(i)*10000}];
    end

    if 1==f_updateDB        
        conn=database('JasperDB','TraderOnly','112358.qwe','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://192.168.1.88:1433;databaseName=JasperDB');
        res = upsert(conn,'JasperDB.dbo.AccountDetail',{'Trade_dt','Account',... %'TotalAsset',
                'TotalReturn','Beta','portfolio_universe','stress','operator','a1','StockPosPnl','HKPosPnl',...
                'NeeqPosPnl','FuPosPnlClose','FuPosPnlSettle','StockTradePnl','HKTradePnl','NeeqTradePnl','FuTradePnlClose','FuTradePnlSettle','FundPosPnl','FundTradePnl'},{'Trade_dt','Account'},volData);     

        fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
    end

end

function [pos,trade,fuPos,account,model,flag] = getDBInfo(s_date,s_ydate,hks_date,hks_ydate,w)
%导入收盘后数据     
    [pos,flag]=getPosition(s_ydate); 
    if 0==flag return; end;
    
    [trade,flag]=getTradeInfo(s_date);    
    if 0==flag return; end;
    
    [fuPos,flag]=getFutureInfo(s_date,s_ydate,hks_date,hks_ydate,pos,trade,w); 
    if 0==flag return; end;
    
    [account,flag]=getAccountInfo(s_ydate); 
    if 0==flag return; end;    
    
    [model,flag]=getModelInfo();
    if 0==flag return; end;
end

function [fundPct,hkPct,ntbPct,bondPct] = getQuotaInfo(pos,trade,s_date,s_ydate,hks_date,hks_ydate,w)
    %取基金的涨跌幅和收盘价    
    rows=(strcmp('F',pos.types)==1);    
    if sum(rows)>0
        codes=pos.codes(rows);
    else 
        codes={};
    end
    rows1=(strcmp('F',trade.types)==1);
    if sum(rows1)>0
        codes=union(codes,trade.codes(rows1));
    end   
    codes=unique(codes);
    if sum(rows)>0 || sum(rows1)>0
        try
            %[w_data,w_code]=w.wsd(codes,'windcode',s_date,s_date);
            %fundPct.codes=w_code;
            %windCode=w_data;
            windCode=codes;
            fundPct.codes=codes;
            [w_data]=w.wsd(windCode,'pct_chg',s_date,s_date);   
            fundPct.pctchanges=w_data/100; 
            [w_data]=w.wsd(windCode,'close',s_date,s_date);  
            fundPct.closeprices=w_data;
            fundPct.tradingStatus=1;
        catch err
            fprintf(err.message);
            fprintf('Error(%s): %s Fund has error in get data. \n',datestr(now(),0),s_date);
            fundPct.tradingStatus=0;
        end  
    else
        fundPct.tradingStatus=0;
    end    
    
    %取港股的涨跌幅和前收盘价(算ratio)
    rows=(strcmp('HKS',pos.types)==1);    
    if sum(rows)>0
        codes=pos.codes(rows);
    else 
        codes={};
    end
    rows1=(strcmp('HKS',trade.types)==1);
    if sum(rows1)>0
        codes=union(codes,trade.codes(rows1));
    end   
    codes=unique(codes);
    if sum(rows)>0 || sum(rows1)>0
        try
%             [w_data,w_code]=w.wsd(codes,'pct_chg',s_date,s_date,'TradingCalendar=HKEX');
               
            [w_data,w_code]=w.wsd(codes,'close',hks_date,hks_date,'TradingCalendar=HKEX'); 
            [w_ydata]=w.wsd(codes,'close',hks_ydate,hks_ydate,'TradingCalendar=HKEX'); 
            hkPct.codes=w_code;
            hkPct.pctchanges=w_data./w_ydata-1; 
            hkPct.closeprices=w_ydata;
            hkPct.tradingStatus=1;           
            [w_data]=w.wsd('HKDCNY.EX','close',s_date,s_date);            
            hkPct.forexrates=w_data;
        catch err
            fprintf(err.message);
            fprintf('Error(%s): %s HK has error in get data. \n',datestr(now(),0),s_date);
            hkPct.tradingStatus=0;
        end  
    else
        hkPct.tradingStatus=0;
    end    
   
    %取新三板的涨跌幅和前收盘价(算ratio)
    rows=(strcmp('NTB',pos.types)==1);    
    if sum(rows)>0
        codes=pos.codes(rows);
    else 
        codes={};
    end
    rows1=(strcmp('NTB',trade.types)==1);
    if sum(rows1)>0
        codes=union(codes,trade.codes(rows1));
    end   
    codes=unique(codes);
    if sum(rows)>0 || sum(rows1)>0
        try
            [w_data,w_code]=w.wsd(codes,'pct_chg',s_date,s_date);   
            if ~iscell(w_data)   
                ntbPct.codes=w_code;
                ntbPct.pctchanges=w_data/100; 
                ntbPct.pctchanges(isnan(ntbPct.pctchanges))=0;
                [w_data]=w.wsd(codes,'close',s_date,s_date);  
                if ~iscell(w_data)   
                    ntbPct.closeprices=w_data;                   
                end   
                ntbPct.tradingStatus=1;
            else
                ntbPct.tradingStatus=0;
            end            
        catch err
            fprintf(err.message);
            fprintf('Error(%s): %s NTB has error in get data. \n',datestr(now(),0),s_date);
            ntbPct.tradingStatus=0;
        end   
    else
        ntbPct.tradingStatus=0;
    end
    
    %取二级市场交易的债券的涨跌幅和前收盘价(算ratio)
    rows=(strcmp('B',pos.types)==1);    
    if sum(rows)>0
        codes=pos.codes(rows);
    else 
        codes={};
    end
    rows1=(strcmp('B',trade.types)==1);
    if sum(rows1)>0
        codes=union(codes,trade.codes(rows1));
    end   
    codes=unique(codes);
    if sum(rows)>0 || sum(rows1)>0
        try
            %[w_data,w_code]=w.wsd(codes,'windcode',s_date,s_date);
            %fundPct.codes=w_code;
            %windCode=w_data;
            windCode=codes;
            bondPct.codes=codes;
            [w_data]=w.wsd(windCode,'pct_chg',s_date,s_date);  
            w_data(isnan(w_data))=0;
            bondPct.pctchanges=w_data/100; 
            [w_data]=w.wsd(windCode,'close',s_ydate,s_date,'PriceAdj=DP');  
            w_data(isnan(w_data))=0;
            bondPct.preclose=w_data(1,:)';
            bondPct.closeprices=w_data(2,:)';
            bondPct.tradingStatus=1;
        catch err
            fprintf(err.message);
            fprintf('Error(%s): %s Bond has error in get data. \n',datestr(now(),0),s_date);
            bondPct.tradingStatus=0;
        end  
    else
        bondPct.tradingStatus=0;
    end
end

%取出各账户持仓
function [pos,flag] = getPosition(s_ydate)
flag=1; %1：成功；0：失败    
    sqlstr=strcat('SELECT [Account],case when [Type]=''S'' then left([WindCode],6) else [WindCode] end,case when side=1 then [Qty]-dzqty else -[Qty] end,[Type],[Multiplier],[ClosePrice]',32,...
        'FROM [JasperDB].[dbo].[JasperPositionNew] where dzqty<qty and Trade_dt=''',s_ydate,''' order by account;');
    %Account not in (SELECT distinct [BaseFundAccount] FROM [JasperDB].[dbo].[JasperPIPEProportion] union',32,...
    %    'SELECT distinct [FundAccount] FROM [JasperDB].[dbo].[JasperPIPEProportion]) and 
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s Position has not found in DB. \n',datestr(now(),0),s_ydate);
        flag=0;        
    else
        pos.accounts=data(:,1);
        pos.codes=data(:,2);
        pos.qtys=cell2mat(data(:,3));
        pos.types=data(:,4);
        pos.multipliers=cell2mat(data(:,5));
        pos.closeprices=cell2mat(data(:,6));        
    end 
end

%取出交易数据
function [trade,flag]=getTradeInfo(s_date)
flag=1;    
    sqlstr=strcat('SELECT [Account],case when [Type]=''S'' then left([WindCode],6) else [WindCode] end,case when side=2 then -[Qty] else [Qty] end,[Type],[Price],[Commission]+[Fee]',32,...
        'FROM [JasperDB].[dbo].[JasperTradeDetail] where Trade_dt=''',s_date,''' order by account;');
    %Account not in (SELECT distinct [BaseFundAccount] FROM [JasperDB].[dbo].[JasperPIPEProportion] union',32,...
    %    'SELECT distinct [FundAccount] FROM [JasperDB].[dbo].[JasperPIPEProportion]) and 
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s trade has not found in DB. \n',datestr(now(),0),s_date);
        flag=0;
    else
        trade.accounts=data(:,1);
        trade.codes=data(:,2);
        trade.qtys=cell2mat(data(:,3));
        trade.types=data(:,4);      
        trade.prices=cell2mat(data(:,5));    
        trade.fees=cell2mat(data(:,6));
    end
end

%取出所有期货合约的收盘价和结算价
function [fuPos,flag]=getFutureInfo(s_date,s_ydate,hks_date,hks_ydate,pos,trade,w)
flag=1;    
    fuPos.codes=unique([pos.codes(strcmp(pos.types,'FU')==1 | strcmp(pos.types,'CTA')==1);trade.codes(strcmp(trade.types,'FU')==1 | strcmp(trade.types,'CTA')==1)]);
    try
        [fuPos.close, fuPos.settle, fuPos.preSettle, fuPos.closePctchg,  fuPos.settlePctchg, fuPos.multipliers]=getFuPrices(fuPos.codes,s_date,s_ydate,hks_date,hks_ydate,w); 
    catch err
        fprintf('Error(%s): %s Future prices is not ready(%s). \n',datestr(now(),0),s_date,err.message);
        flag=0;
    end
end

%%取期货的结算价和收盘价
function [closePrice, settlePrice, preSettlePrice, closePctchg, settlePctchg, multiplier] = getFuPrices(code,date,ydate,hks_date,hks_ydate,w)
%     [w_data]=w.wsd(code,'pct_chg',date,date);   
%     closePctchg=w_data/100; 
    
    [w_data]=w.wsd(code,'close',ydate,date);
    closePrice = w_data(2,:); 
    closePctchg = w_data(2,:)./w_data(1,:)-1;
        
    [w_data]=w.wsd(code,'settle',ydate,date);
    preSettlePrice = w_data(1,:);  
    settlePrice = w_data(2,:);     
    settlePctchg = w_data(2,:)./w_data(1,:)-1; %交易所结算的是收盘价/结算价，所以要重新算
    
    [w_data]=w.wsd(code,'contractmultiplier',date,date);
    multiplier=w_data;
    
    %特殊处理,对香港的期货，按照香港的交易日来取
%     indexC=strfind(code,'.HK');
%     index = find(~(cellfun('isempty', indexC)));
%     tpc=code(index);
%     
%     [w_data]=w.wsd(tpc,'close',hks_ydate,hks_date);
%     closePrice(index) = w_data(2,:); 
%     closePctchg(index) = w_data(2,:)./w_data(1,:)-1;
%         
%     [w_data]=w.wsd(tpc,'settle',hks_ydate,hks_date);
%     preSettlePrice(index) = w_data(1,:);  
%     settlePrice(index) = w_data(2,:);     
%     settlePctchg(index) = w_data(2,:)./w_data(1,:)-1;
end

%取出模型的股票池
function [model,flag]=getModelInfo()
flag=1;
    sqlstr='SELECT [ModelID],[Code],[Weight] FROM [JasperDB].[dbo].[JasperModelInfo] where Trade_dt=(select MAX(trade_dt) FROM [JasperDB].[dbo].[JasperModelInfo]);'; 
    data=DBExcutor88(sqlstr);
    if size(data)<0
        fprintf('Error(%s): model info has not found in DB. \n',datestr(now(),0));
        flag=0;
    else
        model.ids=data(:,1);
        model.codes=data(:,2);
        model.weights=cell2mat(data(:,3));       
    end   
end

% get the account info
function [account,flag]=getAccountInfo(s_ydate)
flag=1;
%05由于分拆了好几个账户，没有合并导数据前手动算；67，CTA
    sqlstr=strcat('SELECT [Account] FROM [JasperDB].[dbo].[AccountDetail] where Account not in (''5A'',''64A'',''64B'',''64C'',''37'',''10N'',''82HK'') and Trade_dt=''',s_ydate,'''');  
    data=DBExcutor88(sqlstr);
    if size(data)<0
        fprintf('Error(%s): account info has not found in DB. \n',datestr(now(),0));
        flag=0;
    else
        account.ids=data(:,1);              
    end   
    jtr=JasperTradingRoom;
    cAccs=jtr.getaccounts(s_ydate);
    [isin,rows]=ismember(account.ids,cAccs.ids);       
    account.capitals=cAccs.assets(rows(isin==1));
end

%计算position pnl
function [posPnl]=calPositionPnl(account,pos,fuPos,pctChg,closePrice,hkPct,ntbPct,fundPct,bondPct,libor,benchmark,dateDiff,cusf)
%flag=1;
posPnl.accounts=[];
posPnl.stockPosPnl=[];
posPnl.subReturn=[];
posPnl.hkPosPnl=[];
posPnl.neeqPosPnl=[];
posPnl.fuPosPnlClose=[];
posPnl.fuPosPnlSettle=[];
posPnl.fundPosPnl=[];
posPnl.alpha=[];
for i=1:length(account.ids)
    capital=account.capitals(i);
%     if capital==0
%         continue;
%     end
    posPnl.accounts=[posPnl.accounts;account.ids(i)];
    %log=strcat(log,sprintf('Info(%s): Dealing with position of account(%s) %s, capital: %f . \n',datestr(now(),0),account.ids{i},account.names{i},capital));
    fprintf('Info(%s): Dealing with position of account(%s), capital: %f . \n',datestr(now(),0),account.ids{i},capital);
    %计算position pnl
    %股票
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & strcmp(pos.types,'S')==1);
    if sum(rows)>0
        stock.codes=pos.codes(rows);     
        stock.qtys=pos.qtys(rows);    
        [isin,rows]=ismember(stock.codes,pctChg.codes);
        stock.pctchgs=pctChg.pctchanges(rows(isin==1));
        
        %去掉没有RQuotation的股票，大部分是新股
        if ~isempty(rows(isin==0))
            row=find(isin==0);
            fprintf('Info(%s): %s do not have RQuotation. \n',datestr(now(),0),stock.codes{row});
            stock.codes(row)=[];
            stock.qtys(row)=[];          
        end
        
        if size(stock.codes,2)>0
            [isin,rows]=ismember(stock.codes,closePrice.codes);
            stock.closeprices=closePrice.preprices(rows(isin==1));

            stock.ratios=stock.qtys.*stock.closeprices/capital;
            posPnl.stockPosPnl=[posPnl.stockPosPnl;sum(stock.ratios.*stock.pctchgs)];    
            %计算return，当做100%持仓计算
            subRatios=stock.qtys.*stock.closeprices/sum(stock.qtys.*stock.closeprices);
            posPnl.subReturn=[posPnl.subReturn;sum(subRatios.*stock.pctchgs)];
            
            %根据实际仓位市值比例来计算benchmark
            subMV=closePrice.mvs(rows(isin==1));
            bmRatio1=sum(subRatios(subMV>=200))+benchmark.ratio*sum(subRatios(subMV>=100 & subMV<200));
            bmRatio2=sum(subRatios(subMV<100))+(1-benchmark.ratio)*sum(subRatios(subMV>=100 & subMV<200));           
            i_benchmark=(bmRatio1*benchmark.index1+bmRatio2*benchmark.index2);
            posPnl.alpha=[posPnl.alpha;posPnl.subReturn(end)-i_benchmark];

            fprintf('Info(%s): account(%s) : has dealed %f stock position records. \n',datestr(now(),0),account.ids{i},...
                length(stock.codes));
            if strcmp('86',account.ids{i}) == 1 || strcmp('88',account.ids{i}) == 1 %boothbay, argo fund的stock持仓减去1month Libor+90bps        
                posPnl.stockPosPnl(end)=posPnl.stockPosPnl(end)-abs(sum(stock.ratios)*(libor(1)/100+0.009)/365*dateDiff);  
            end
            
            if strcmp('88',account.ids{i}) == 1 %记录argo fund的多头仓位市值
                posLongMV88=sum(stock.qtys.*stock.closeprices); 
            end
        else
            posPnl.stockPosPnl=[posPnl.stockPosPnl;0];   
            posPnl.subReturn=[posPnl.subReturn;0];
            posPnl.alpha=[posPnl.alpha;0];            
        end
    else
        posPnl.stockPosPnl=[posPnl.stockPosPnl;0];   
        posPnl.subReturn=[posPnl.subReturn;0];
        posPnl.alpha=[posPnl.alpha;0];
        posLongMV88=0;
    end
        
    %Fund 
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & strcmp(pos.types,'F')==1);
    if sum(rows)>0 && 1==fundPct.tradingStatus
        stock.codes=pos.codes(rows);     
        stock.qtys=pos.qtys(rows);   
% 		stock.closeprices=pos.closeprices(rows); 		
        [isin,rows]=ismember(stock.codes,fundPct.codes);
        stock.pctchgs=fundPct.pctchanges(rows(isin==1));
        stock.closeprices=fundPct.closeprices(rows(isin==1));

        stock.ratios=stock.qtys.*stock.closeprices/capital;
        posPnl.fundPosPnl=[posPnl.fundPosPnl;sum(stock.ratios.*stock.pctchgs)];            

        fprintf('Info(%s): account(%s) : has dealed %f fund position records. \n',datestr(now(),0),account.ids{i},...
            length(stock.codes));  
        
        if strcmp('86',account.ids{i}) == 1 || strcmp('88',account.ids{i}) == 1 %boothbay,argo fund的fund持仓减去费用
            posPnl.fundPosPnl(end)=posPnl.fundPosPnl(end)-abs(sum(stock.ratios)*(0.045-libor(2)/100)/365*dateDiff);  
        end    
        
        if strcmp('88',account.ids{i}) == 1 %记录argo fund的空头仓位市值
            posShortMV88=sum(stock.qtys.*stock.closeprices); 
        end  
    else
        posPnl.fundPosPnl=[posPnl.fundPosPnl;0];
        posShortMV88=0;
    end
        
    %港股HKS
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & strcmp(pos.types,'HKS')==1);    
    if sum(rows)>0 && 1==hkPct.tradingStatus
        stock.codes=pos.codes(rows);
        stock.qtys=pos.qtys(rows);

        [isin,rows]=ismember(stock.codes,hkPct.codes);
        stock.pctchgs=hkPct.pctchanges(rows(isin==1));
        stock.closeprices=hkPct.closeprices(rows(isin==1)); 
        stock.ratios=stock.qtys.*stock.closeprices*hkPct.forexrates/capital;

        posPnl.hkPosPnl=[posPnl.hkPosPnl;sum(stock.ratios.*stock.pctchgs)]; 

        fprintf('%s \n Info(%s): account(%s) : has dealed %f HK stock position records. \n',datestr(now(),0),account.ids{i},...
            length(stock.codes));
    else
         posPnl.hkPosPnl=[posPnl.hkPosPnl;0]; 
    end
    
     %新三板：NTB(NEEQ)
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & strcmp(pos.types,'NTB')==1);    
    if sum(rows)>0 && 1==ntbPct.tradingStatus
        stock.codes=pos.codes(rows);
        stock.qtys=pos.qtys(rows);

        [isin,rows]=ismember(stock.codes,ntbPct.codes);
        stock.pctchgs=ntbPct.pctchanges(rows(isin==1));
        stock.closeprices=ntbPct.closeprices(rows(isin==1));
        stock.ratios=stock.qtys.*stock.closeprices/capital;

        posPnl.neeqPosPnl=[posPnl.neeqPosPnl;sum(stock.ratios.*stock.pctchgs)]; 

        fprintf('Info(%s): account(%s) : has dealed %f HK stock position records. \n',datestr(now(),0),account.ids{i},...
            length(stock.codes));
    else
         posPnl.neeqPosPnl=[posPnl.neeqPosPnl;0]; 
    end
    
    %期货
    %取收盘价算一个(发trading pnl)，结算价算一个(发净值)  
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & (strcmp(pos.types,'FU')==1 | strcmp(pos.types,'CTA')==1));
    if sum(rows)>0
        fu.codes=pos.codes(rows);
        fu.qtys=pos.qtys(rows);

        [isin,rows]=ismember(fu.codes,fuPos.codes);       
        fu.settleprices=fuPos.preSettle(rows(isin==1))';
        fu.closePctchg=fuPos.closePctchg(rows(isin==1))';
        fu.settlePctchg=fuPos.settlePctchg(rows(isin==1))'; 
        fu.multipliers=fuPos.multipliers(rows(isin==1));

        %fu.ratiosClose=fu.closeprices.*fu.qtys.*fu.multipliers/capital;
        fu.ratios=fu.settleprices.*fu.qtys.*fu.multipliers/capital;
        posPnl.fuPosPnlClose=[posPnl.fuPosPnlClose;sum(fu.ratios.*fu.closePctchg)];
        posPnl.fuPosPnlSettle=[posPnl.fuPosPnlSettle;sum(fu.ratios.*fu.settlePctchg)];
        fprintf('Info(%s): account(%s) : has dealed %f future position records. \n',...
            datestr(now(),0),account.ids{i},length(fu.codes));  
    else
        posPnl.fuPosPnlClose=[posPnl.fuPosPnlClose;0];
        posPnl.fuPosPnlSettle=[posPnl.fuPosPnlSettle;0];
    end
    
    %Bond 算到股票里
    rows=find(strcmp(pos.accounts,account.ids{i})==1 & strcmp(pos.types,'B')==1);
    if sum(rows)>0 && 1==bondPct.tradingStatus
        stock.codes=pos.codes(rows);     
        stock.qtys=pos.qtys(rows);   
				
        [isin,rows]=ismember(stock.codes,bondPct.codes);
        stock.pctchgs=bondPct.pctchanges(rows(isin==1));
        stock.closeprices=bondPct.closeprices(rows(isin==1)); 

        stock.ratios=stock.qtys.*stock.closeprices/capital;
        posPnl.stockPosPnl(end)=posPnl.stockPosPnl(end)+sum(stock.ratios.*stock.pctchgs);            

        fprintf('Info(%s): account(%s) : has dealed %f bond position records. \n',datestr(now(),0),account.ids{i},...
            length(stock.codes));    
    end
    
    %特殊处理
    if strcmp('88',account.ids{i}) == 1 %argo fund 要减去汇率盈亏
        posPnl.stockPosPnl(end)=posPnl.stockPosPnl(end)-(posLongMV88+posShortMV88)/capital*cusf;        
    end
end

end

%计算trading pnl
function [tradingPnl]=calTradingPnl(account,trade,fuPos,closePrice,hkPct,ntbPct,fundPct,bondPct)
    %股票 
    tradingPnl.accounts=[];
    tradingPnl.stockTradePnl=[];
    tradingPnl.hkTradePnl=[];
    tradingPnl.neeqTradePnl=[];
    tradingPnl.fuTradePnlClose=[];
    tradingPnl.fuTradePnlSettle=[];
    tradingPnl.fundTradePnl=[];
    for i=1:length(account.ids)
         capital=account.capitals(i);
%         if capital==0
%             continue;
%         end
        tradingPnl.accounts=[tradingPnl.accounts;account.ids(i)];
        rows=strcmp(trade.accounts,account.ids{i})==1 & strcmp(trade.types,'S')==1;
        if sum(rows)>0
            stock.codes=trade.codes(rows);
            stock.qtys=trade.qtys(rows);
            stock.prices=trade.prices(rows);
            stock.fees=trade.fees(rows);
            [isin,rows]=ismember(stock.codes,closePrice.codes);
            stock.closeprices=closePrice.prices(rows(isin==1));
            
            %去掉没有SQuotation的股票
            if ~isempty(rows(isin==0))
                row=find(isin==0);
                fprintf('Info(%s): %s do not have SQuotation. \n',datestr(now(),0),cell2mat(stock.codes(row)));
                stock.codes(row)=[];
                stock.qtys(row)=[]; 
                stock.prices(row)=[];
                stock.fees(row)=[];
            end
            if size(stock.codes,2)>0
                tradingPnl.stockTradePnl=[tradingPnl.stockTradePnl;(sum(stock.qtys.*(stock.closeprices-stock.prices))-sum(stock.fees))/capital];            
                fprintf('Info(%s): account(%s) : has dealed %f stock trading records. \n',datestr(now(),0),account.ids{i},...
                    length(stock.codes));
            else
                tradingPnl.stockTradePnl=[tradingPnl.stockTradePnl;0];
            end
        else
            tradingPnl.stockTradePnl=[tradingPnl.stockTradePnl;0];
        end

        %Fund
        rows=strcmp(trade.accounts,account.ids{i})==1 & strcmp(trade.types,'F')==1;
        if sum(rows)>0 && 1==fundPct.tradingStatus
            stock.codes=trade.codes(rows);
            stock.qtys=trade.qtys(rows);
            stock.prices=trade.prices(rows);
            stock.fees=trade.fees(rows);
            [isin,rows]=ismember(stock.codes,fundPct.codes);
            stock.closeprices=fundPct.closeprices(rows(isin==1));

           tradingPnl.fundTradePnl=[tradingPnl.fundTradePnl;(sum(stock.qtys.*(stock.closeprices-stock.prices))-sum(stock.fees))/capital];
            fprintf('Info(%s): account(%s) : (%s) has dealed %f fund stock trading records. \n',datestr(now(),0),account.ids{i},...
                length(stock.codes));   
        else
            tradingPnl.fundTradePnl=[tradingPnl.fundTradePnl;0];
        end
        
        %港股HKS
        rows=strcmp(trade.accounts,account.ids{i})==1 & strcmp(trade.types,'HKS')==1;
        if sum(rows)>0
            stock.codes=trade.codes(rows);
            stock.qtys=trade.qtys(rows);
            stock.prices=trade.prices(rows);
            stock.fees=trade.fees(rows);
            [isin,rows]=ismember(stock.codes,hkPct.codes);
            stock.closeprices=hkPct.closeprices(rows(isin==1));

            tradingPnl.hkTradePnl=[tradingPnl.hkTradePnl;(sum(stock.qtys.*(stock.closeprices-stock.prices))-sum(stock.fees))*hkPct.forexrates/capital];
            fprintf('Info(%s): account(%s) : (%s) has dealed %f hk stock trading records. \n',datestr(now(),0),account.ids{i},...
                length(stock.codes));
        else
             tradingPnl.hkTradePnl=[tradingPnl.hkTradePnl;0]; 
        end
        
        %新三板：NTB(NEEQ)
        rows=strcmp(trade.accounts,account.ids{i})==1 & strcmp(trade.types,'NTB')==1;
        if sum(rows)>0
            stock.codes=trade.codes(rows);
            stock.qtys=trade.qtys(rows);
            stock.prices=trade.prices(rows);
            stock.fees=trade.fees(rows);
            [isin,rows]=ismember(stock.codes,ntbPct.codes);
            stock.closeprices=ntbPct.closeprices(rows(isin==1));

            tradingPnl.neeqTradePnl=[tradingPnl.neeqTradePnl;(sum(stock.qtys.*(stock.closeprices-stock.prices))-sum(stock.fees))/capital];
            fprintf('Info(%s): account(%s) : (%s) has dealed %f ntb stock trading records. \n',datestr(now(),0),account.ids{i},...
                length(stock.codes));
        else
             tradingPnl.neeqTradePnl=[tradingPnl.neeqTradePnl;0]; 
        end
        
        %期货
        rows=strcmp(trade.accounts,account.ids{i})==1 & (strcmp(trade.types,'FU')==1 | strcmp(trade.types,'CTA')==1);
        if sum(rows)>0
            fu.codes=trade.codes(rows);
            fu.qtys=trade.qtys(rows);
            fu.prices=trade.prices(rows);
            fu.fees=trade.fees(rows);
            
            [isin,rows]=ismember(fu.codes,fuPos.codes);
            fu.closeprices=fuPos.close(rows(isin==1))';
            fu.settleprices=fuPos.settle(rows(isin==1))';
            fu.multipliers=fuPos.multipliers(rows(isin==1));

            tradingPnl.fuTradePnlClose=[tradingPnl.fuTradePnlClose;(sum((fu.closeprices-fu.prices).*fu.qtys.*fu.multipliers)-sum(fu.fees))/capital];
            tradingPnl.fuTradePnlSettle=[tradingPnl.fuTradePnlSettle;(sum((fu.settleprices-fu.prices).*fu.qtys.*fu.multipliers)-sum(fu.fees))/capital];
            fprintf('Info(%s): account(%s) : has dealed %f future trading records. \n',...
                datestr(now(),0),account.ids{i},length(fu.codes));
        else
            tradingPnl.fuTradePnlClose=[tradingPnl.fuTradePnlClose;0];
            tradingPnl.fuTradePnlSettle=[tradingPnl.fuTradePnlSettle;0];
        end
        
        %Bond
        rows=strcmp(trade.accounts,account.ids{i})==1 & strcmp(trade.types,'B')==1;
        if sum(rows)>0 && 1==bondPct.tradingStatus
            stock.codes=trade.codes(rows);
            stock.qtys=trade.qtys(rows);
            stock.prices=trade.prices(rows);
            stock.fees=trade.fees(rows);
            [isin,rows]=ismember(stock.codes,bondPct.codes);
            stock.closeprices=bondPct.closeprices(rows(isin==1));

            tradingPnl.stockTradePnl(end)=tradingPnl.stockTradePnl(end)+(sum(stock.qtys.*(stock.closeprices-stock.prices))-sum(stock.fees))/capital;
            fprintf('Info(%s): account(%s) : (%s) has dealed %f bond stock trading records. \n',datestr(now(),0),account.ids{i},...
                length(stock.codes));       
        end
    end
end

%计算定增股票池个账户收益
function [posPnl] = addPIPEPnl(posPnl,account,tradingPnl,s_date)
    sqlstr=strcat('SELECT rtrim([FundAccount]),[Proportion]*(SUM(b.pnl)),[Proportion] FROM [JasperDB].[dbo].[JasperPIPEProportion] a,[JasperDB].[dbo].[JasperPrivatePlacementPosition] b ',32,...
        'where b.Trade_dt=''',s_date,''' group by [FundAccount],[Proportion] order by [FundAccount]');
    data=DBExcutor88(sqlstr);
    if size(data)<0
        fprintf('Error(%s): PIPE Total Pnl has not found in DB. \n',datestr(now(),0));  
        return;
    else
        pipe.accounts=data(:,1);
        pipe.pnlamounts=cell2mat(data(:,2)); 
        pipe.proportions=cell2mat(data(:,3)); 
    end  
    
    %把底层10的收益分到master层
    row=strcmp('10',account.ids)==1;
    if sum(row) > 0 
        capital=account.capitals(row);    
        pnlamount=capital*(posPnl.stockPosPnl(row)+posPnl.hkPosPnl(row)+posPnl.neeqPosPnl(row)+posPnl.fuPosPnlSettle(row)+tradingPnl.stockTradePnl(row)+tradingPnl.hkTradePnl(row)+tradingPnl.neeqTradePnl(row)+tradingPnl.fuTradePnlSettle(row));    
        posPnl.stockPosPnl(row)=posPnl.stockPosPnl(row)+sum(pipe.pnlamounts)/capital;
    else
        pnlamount=0;
    end
    pipe.pnlamounts=pipe.pnlamounts+pnlamount*pipe.proportions;
    [isin,rows]=ismember(posPnl.accounts,pipe.accounts);    
    posPnl.stockPosPnl(isin==1)=posPnl.stockPosPnl(isin==1)+pipe.pnlamounts(rows(isin==1))./account.capitals(isin==1);
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
