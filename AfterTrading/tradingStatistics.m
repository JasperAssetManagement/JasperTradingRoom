function [ log ] = tradingStatistics(s_date,s_ydate,closePrice)
% statistics of trading detail
%   Detailed explanation goes here
[pos,accTrade,stockTrade,subStockTrade,account,forbiddenTrading,flag] = getDBInfo(s_date,s_ydate);
if 0==flag return; end;

%统计公司按持仓计算的总交易量和每个账户的交易量
stockAmounts=sum(pos.amounts);
tradeAmounts=sum(accTrade.amounts);

tradeRatio=tradeAmounts/stockAmounts; %全公司的交易占比

%按账户统计trade ratio
[isin, rows]=ismember(accTrade.accounts,pos.accounts);
accTrade.ratios=accTrade.amounts(isin==1)./pos.amounts(rows(isin==1));

%统计每个票的成交占比
[isin, rows]=ismember(stockTrade.codes,closePrice.codes);
if ~isempty(rows(isin==0))
    row=find(isin==0);
    fprintf('Info(%s): %s do not have stock close price. \n',datestr(now(),0),stockTrade.codes{row});
    stockTrade.codes(row)=[];
    stockTrade.amounts(row)=[];          
end
stockTrade.ratios=stockTrade.amounts./closePrice.amounts(rows(isin==1));

%分别统计每个票买卖的成交占比
[isin, rows]=ismember(subStockTrade.codes,closePrice.codes);
if ~isempty(rows(isin==0))
    row=find(isin==0);   
    subStockTrade.codes(row)=[];
    subStockTrade.amounts(row)=[];          
end
subStockTrade.ratios=subStockTrade.amounts./closePrice.amounts(rows(isin==1));

%排序输出
% outPut(tradeRatio,accTrade,subStockTrade,account,s_date);
log=sOutPut(tradeRatio,accTrade,subStockTrade,account,forbiddenTrading,s_date);
% to='neo.lin@jasperam.com';
% subject='testTradeInfo';
% sendMail(to,subject,log);
end

function [pos,accTrade,stockTrade,subStockTrade,account,forbiddenTrading,flag] = getDBInfo(s_date,s_ydate)
%导入收盘后数据     
    [pos,flag]=getPosition(s_ydate); 
    if 0==flag return; end;
    
    [accTrade,stockTrade,subStockTrade,flag]=getTradeInfo(s_date);    
    if 0==flag return; end; 
    
    [account,flag]=getAccountInfo();
    if 0==flag return; end;
    
    [forbiddenTrading] = getForbiddenTrading(s_date);
    if 0==flag return; end;
end

%取出各账户持仓
function [pos,flag] = getPosition(s_ydate)
flag=1; %1：成功；0：失败    
    sqlstr=strcat('SELECT rtrim([Account]),sum(([Qty]-dzqty)*[ClosePrice]) as amount',32,...
        'FROM [JasperDB].[dbo].[JasperPosition] a where dzqty<qty and type=''S'' and Trade_dt=''',s_ydate,''' group by account order by account;');
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s Position has not found in DB. \n',datestr(now(),0),s_ydate);
        flag=0;        
    else
        pos.accounts=data(:,1);       
        pos.amounts=cell2mat(data(:,2));  
    end 
end

%取出交易数据
function [accTrade,stockTrade,subStockTrade,flag]=getTradeInfo(s_date)
flag=1;    
    sqlstr=strcat('SELECT rtrim([Account]),SUM(qty*Price) as amount FROM [JasperDB].[dbo].[JasperTradeDetail]',... 
        'where Trade_dt=''',s_date,''' and type=''S'' and Account not in (''5A'',''64A'',''5B'',''64B'') group by account order by account;');   
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s trade has not found in DB. \n',datestr(now(),0),s_date);
        flag=0;
    else
        accTrade.accounts=data(:,1);
        accTrade.amounts=cell2mat(data(:,2));           
    end
    
    sqlstr=strcat('SELECT [windcode],SUM(qty*Price) as amount,b.s_info_name FROM [JasperDB].[dbo].[JasperTrade] a,',...
        'DBAL.[WINDFILESYNC].[dbo].[AShareDescription] b where Trade_dt=''',s_date,''' and type=''S'' and a.windcode=b.s_info_windcode',32,...
        'group by windcode,b.s_info_name order by windcode;');   
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s trade has not found in DB. \n',datestr(now(),0),s_date);
        flag=0;
    else
        stockTrade.codes=data(:,1);
        stockTrade.amounts=cell2mat(data(:,2));
        stockTrade.names=data(:,3);
    end
    
    sqlstr=strcat('SELECT [windcode],SUM(qty*Price) as amount,b.s_info_name,rtrim(side) FROM [JasperDB].[dbo].[JasperTrade] a,',...
        'DBAL.[WINDFILESYNC].[dbo].[AShareDescription] b where Trade_dt=''',s_date,''' and type=''S'' and a.windcode=b.s_info_windcode',32,...
        'group by windcode,b.s_info_name,side order by windcode;');   
    data=DBExcutor88(sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s trade has not found in DB. \n',datestr(now(),0),s_date);
        flag=0;
    else
        subStockTrade.codes=data(:,1);
        subStockTrade.amounts=cell2mat(data(:,2));
        subStockTrade.names=data(:,3);
        subStockTrade.side=data(:,4);
    end
end

function [account,flag]=getAccountInfo()
flag=1;
    sqlstr=strcat('SELECT s_key,s_value FROM [JasperDB].[dbo].[Dictionary] where s_type=''01'''); 
    data=DBExcutor88(sqlstr);
    if size(data)<0
        fprintf('Error(%s): Dictionary info has not found in DB. \n',datestr(now(),0));
        flag=0;
    else
        account.ids=data(:,1);       
        account.names=data(:,2);
    end   
end

function [forbiddenTrading] = getForbiddenTrading(s_date)
forbiddenTrading.accounts=[];
forbiddenTrading.codes=[];
forbiddenTrading.names=[];
forbiddenTrading.sides=[];
%卖了需要买的票
    sqlstr=strcat('select distinct rtrim(a.Account),a.WindCode,a.Name,''卖出'' from [JasperDB].[dbo].[JasperTrade] a where WindCode in (',32,... 
        'SELECT [WindCode] FROM [JasperDB].[dbo].[JasperOtherOrder] where Trade_dt=''',s_date,''' and AvailableDays>0) and a.side=2 and a.Trade_dt=''',s_date,''';');   
    data=DBExcutor88(sqlstr);
    if size(data)>0       
        forbiddenTrading.accounts=[forbiddenTrading.accounts;data(:,1)];
        forbiddenTrading.codes=[forbiddenTrading.codes;data(:,2)];
        forbiddenTrading.names=[forbiddenTrading.names;data(:,3)];
        forbiddenTrading.sides=[forbiddenTrading.sides;data(:,4)];
    end
%买了需要卖的票
    sqlstr=strcat('select distinct rtrim(a.Account),a.WindCode,a.Name,''买入'' from [JasperDB].[dbo].[JasperTrade] a,(select * from [JasperDB].[dbo].[JasperForbiddenStock]',32,... 
        'where StartDt=''',s_date,''' and [IsSell]=''TRUE'' and account=''0'') b',32,...
        'where a.Trade_dt=''',s_date,''' and a.WindCode=b.WindCode and a.Side=1;');   
    data=DBExcutor88(sqlstr);
    if size(data)>0       
        forbiddenTrading.accounts=[forbiddenTrading.accounts;data(:,1)];
        forbiddenTrading.codes=[forbiddenTrading.codes;data(:,2)];
        forbiddenTrading.names=[forbiddenTrading.names;data(:,3)];
        forbiddenTrading.sides=[forbiddenTrading.sides;data(:,4)];
    end
%交易了不该交易的股票
    sqlstr=strcat('select distinct rtrim(Account),WindCode,Name,case Side when 1 then ''买入'' else ''卖出'' end from [JasperDB].[dbo].[JasperTrade]',32,... 
        'where Trade_dt=''',s_date,'''and WindCode in ',32,...
        '(select WindCode from [JasperDB].[dbo].[JasperForbiddenStock] where (EndDt>''',s_date,''' or Len(EndDt)=0) and Account=''0''',32,...
        'except select WindCode from [JasperDB].[dbo].[JasperForbiddenStock] where StartDt=''',s_date,''' and [IsSell]=''TRUE''',32,...
        'except select [WindCode] FROM [JasperDB].[dbo].[JasperOtherOrder] where Trade_dt=''',s_date,''' and AvailableDays>0);');   
    data=DBExcutor88(sqlstr);
    if size(data)>0       
        forbiddenTrading.accounts=[forbiddenTrading.accounts;data(:,1)];
        forbiddenTrading.codes=[forbiddenTrading.codes;data(:,2)];
        forbiddenTrading.names=[forbiddenTrading.names;data(:,3)];
        forbiddenTrading.sides=[forbiddenTrading.sides;data(:,4)];
    end
end

function [] = outPut(tradeRatio,accTrade,subStockTrade,account,s_date)
fprintf('*************汇总统计信息************* \n');
fprintf('全天(%s)所有交易型产品交易占持仓量比：%3.2f%%. 金额：%7.2f万 \n',s_date,roundn(tradeRatio*100,-4),roundn(sum(accTrade.amounts)/10000,-2));
fprintf('所有交易型产品交易占持仓量比平均数：%3.2f%%. \n \n',roundn(mean(accTrade.ratios)*100,-4));
fprintf('*************账户统计信息(>0.15)************* \n');
[ratio, index]=sort(accTrade.ratios,'descend');
accs=sum(accTrade.ratios>.15);
for i=1:accs%length(index)
    name=account.names{strcmp(accTrade.accounts{index(i)},account.ids)==1};
    fprintf('交易量占持仓比例第 %d 的产品：%s(%s)；比例：%3.2f%%. 金额：%6.2f万 \n',i,name,accTrade.accounts{index(i)},roundn(ratio(i)*100,-4),...
        roundn(accTrade.amounts(index(i))/10000,-2));
end
fprintf('\n *************个股统计信息************* \n');
[~, index]=sort(subStockTrade.ratios,'descend');
subSide=subStockTrade.side(index);
% stockCodes=subStockTrade.codes(index);
% stockNames=subStockTrade.names(index);
buyIndex=index(strcmp(subSide,'1')==1);
sellIndex=index(strcmp(subSide,'2')==1);
for i=1:5
    fprintf('单只股票买入量占全天成交金额第 %d 的股票：%s(%s)；比例：%3.2f%%. 金额：%6.2f万  \n',i,subStockTrade.codes{buyIndex(i)},subStockTrade.names{buyIndex(i)},...
        roundn(subStockTrade.ratios(buyIndex(i))*100,-4),roundn(subStockTrade.amounts(buyIndex(i))/10000,-2));
end
fprintf('\n');
for i=1:5
    fprintf('单只股票卖出量占全天成交金额第 %d 的股票：%s(%s)；比例：%3.2f%%. 金额：%6.2f万  \n',i,subStockTrade.codes{sellIndex(i)},subStockTrade.names{sellIndex(i)},...
        roundn(subStockTrade.ratios(sellIndex(i))*100,-4),roundn(subStockTrade.amounts(sellIndex(i))/10000,-2));
end
end

function [log] = sOutPut(tradeRatio,accTrade,subStockTrade,account,forbiddenTrading,s_date)
log=sprintf('*************汇总统计信息*************');
log=sprintf('%s \n 全天(%s)所有交易型产品交易占持仓量比：%3.2f%%. 金额：%7.2f万',log,s_date,roundn(tradeRatio*100,-4),roundn(sum(accTrade.amounts)/10000,-2));
log=sprintf('%s \n 所有交易型产品交易占持仓量比平均数：%3.2f%%.',log,roundn(mean(accTrade.ratios)*100,-4));
log=sprintf('%s \n\n *************账户统计信息(>0.15)*************',log);
[ratio, index]=sort(accTrade.ratios,'descend');
accs=sum(accTrade.ratios>.15);
for i=1:accs%length(index)
    name=account.names{strcmp(accTrade.accounts{index(i)},account.ids)==1};
    log=sprintf('%s \n 交易量占持仓比例第 %d 的产品：%s(%s)；比例：%3.2f%%. 金额：%6.2f万',log,i,name,accTrade.accounts{index(i)},roundn(ratio(i)*100,-4),...
        roundn(accTrade.amounts(index(i))/10000,-2));
end
log=sprintf('%s \n\n *************个股统计信息*************',log);
[~, index]=sort(subStockTrade.ratios,'descend');
subSide=subStockTrade.side(index);
% stockCodes=subStockTrade.codes(index);
% stockNames=subStockTrade.names(index);
buyIndex=index(strcmp(subSide,'1')==1);
sellIndex=index(strcmp(subSide,'2')==1);
for i=1:5
    log=sprintf('%s \n 单只股票买入量占全天成交金额第 %d 的股票：%s(%s)；比例：%3.2f%%. 金额：%6.2f万 ',log,i,subStockTrade.codes{buyIndex(i)},subStockTrade.names{buyIndex(i)},...
        roundn(subStockTrade.ratios(buyIndex(i))*100,-4),roundn(subStockTrade.amounts(buyIndex(i))/10000,-2));
end
log=sprintf('%s \n\n',log);
for i=1:5
    log=sprintf('%s \n 单只股票卖出量占全天成交金额第 %d 的股票：%s(%s)；比例：%3.2f%%. 金额：%6.2f万 ',log,i,subStockTrade.codes{sellIndex(i)},subStockTrade.names{sellIndex(i)},...
        roundn(subStockTrade.ratios(sellIndex(i))*100,-4),roundn(subStockTrade.amounts(sellIndex(i))/10000,-2));
end
log=sprintf('%s \n\n *************禁投股票交易*************',log);
[sortedForbiddenAcc,index]=sort(forbiddenTrading.accounts);
sortedForbiddenCode=forbiddenTrading.codes(index);
sortedForbiddenName=forbiddenTrading.names(index);
sortedForbiddenSide=forbiddenTrading.sides(index);
for i=1:size(forbiddenTrading.codes,1)
    name=account.names{strcmp(sortedForbiddenAcc{i},account.ids)==1};
    log=sprintf('%s \n 交易禁投股票产品：%s(%s)；%s%s(%s)',log,sortedForbiddenAcc{i},name,sortedForbiddenSide{i},sortedForbiddenCode{i},sortedForbiddenName{i});
end
end


