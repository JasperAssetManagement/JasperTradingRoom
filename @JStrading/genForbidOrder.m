function genForbidOrder()
% 自动生成各产品卖出非模型股票以及公共禁止池股票清单。
% 两个缺陷：1.事件的股票也会在卖单中。(增加了otherposition功能)
%           2.暂时缺少剔除涨停股票的功能。
% 
% - by Lary 2017.06.05

%% 获取各产品需要卖出股票清单
jst = JStrading;
w = windmatlab;

dVolLimitRatio = 0.2; % 合计卖出量占过去10日日均成交量的20%

cOtherList = jst.getsqlrtn(jst.dbconn,'select distinct windcode from JasperDB.dbo.JasperOtherOrder where trade_dt = (select max(trade_dt) from JasperDB.dbo.JasperOtherOrder)');

cModelList = jst.getLatestModelList;
cBanList = jst.getLatestForbiddenList;
cBanListNoLimit = jst.getLatestForbiddenList2;
tHolding = getJasperPosition(jst);
tHolding = sortrows(tHolding,'windcode','ascend');
bGoodStock = cellfun(@(x)(strcmpi(x(1:2),'60') | strcmpi(x(1:2),'30') | strcmpi(x(1:2),'00')),tHolding.windcode);
tSH = tHolding(bGoodStock,:);
cBadCodes = setdiff(unique(tSH.windcode),setdiff(union(cOtherList,cModelList),cBanList));
tSell = cell2table(cBadCodes,'VariableNames',{'windcode'});
tSellHolding = innerjoin(tSH,tSell);

%% 剔除停牌个股 获取过去10日日均成交量
tTotalSell = cell2table(Utilities_zjx.pivottable(table2cell(tSellHolding),1,4, @sum),'VariableNames',{'windcode','totqty'});
tped = Utilities_zjx.tradingdate(today-1);
tptd = Utilities_zjx.tradingdate(tped,1);
tpsd = Utilities_zjx.tradingdate(tped,-10);
tpche = datestr(tped,'yyyymmdd');
tpcht = datestr(tptd,'yyyymmdd');
tpchs = datestr(tpsd,'yyyymmdd');
tpdata = w.wss(tTotalSell.windcode,'avg_vol_per','unit=1',['startDate=' tpchs],['endDate=' tpche]);
bNoLimit = ismember(tTotalSell.windcode,cBanListNoLimit);
tpdata(bNoLimit) = inf;
cStatYst = w.wss(tTotalSell.windcode,'trade_status',['tradeDate=' tpche]);
cStatToday = w.wss(tTotalSell.windcode,'trade_status',['tradeDate=' tpcht]);
bResume = cellfun(@(x)~isempty(strfind(x,'停牌')),cStatYst) & cellfun(@(x)~isempty(strfind(x,'交易')),cStatToday);
bStop = cellfun(@(x)~isempty(strfind(x,'停牌')),cStatToday);
tpdata(bResume | tpdata<1000000) = inf;
tpdata(bStop) = 0;
tTotalSell.limitamt = tpdata;
tTotalSell.lastclose = w.wss(tTotalSell.windcode,'close');
tTotalSell = tTotalSell(~isnan(tTotalSell.lastclose),:);

%% 生成卖单
tSellHolding = innerjoin(tSH,tTotalSell);
tSellHolding.limitamt = fix(tSellHolding.limitamt.*tSellHolding.qty./tSellHolding.totqty*dVolLimitRatio/100)*100;

tSellHolding.sellamt = min(tSellHolding.limitamt,tSellHolding.qty);
tSellHolding.sellamt(tSellHolding.qty<1000) = tSellHolding.qty(tSellHolding.qty<1000);
tSellHolding.sellamt(tSellHolding.limitamt==0) = 0;
tSellPos = tSellHolding(tSellHolding.sellamt>0,{'windcode','name','account','sellamt','lastclose'});
tSellPos = sortrows(tSellPos,{'account'});
tpc = [tSellPos.account num2cell(tSellPos.sellamt.*tSellPos.lastclose)];
cAccountView = Utilities_zjx.pivottable(tpc,1,2,@sum);
tAccountView = cell2table(cAccountView,'VariableNames',{'id','totsellamt'});
tInfo = JStrading.getforbidinfo;
tAccountView = outerjoin(tAccountView,tInfo);
tAccountView.id = tAccountView.id_tAccountView;
tAccountView = tAccountView(:,{'id','totsellamt','trader'});
tAccountView = sortrows(tAccountView,{'trader','id'});
chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\自动卖单汇总-' tpcht '.csv'];
if exist(chFile,'file')
    delete(chFile)
end
bNoTrader = cellfun(@(x)isempty(x),tAccountView.trader);
tAccountView.trader(bNoTrader) = repmat({'unkonw'},sum(bNoTrader),1);
tAccountView.totsellamt = fix(tAccountView.totsellamt);
bNoTrade = cellfun(@(x)isempty(x),tAccountView.id);
tAccountView = tAccountView(~bNoTrade,:);
cAccountView = table2cell(tAccountView);
Utilities_zjx.cell2csv(chFile,cAccountView)

%% 生成各交易员各产品的卖单金额汇总

cTraders = unique(tInfo.trader);
for iTrader = 1:numel(cTraders)
    chTrader = cTraders{iTrader};
    if strcmpi(chTrader,'Lary')
        continue
    end
    chTrader = cTraders{iTrader};
    tpdir = ['Z:\' chTrader '\自动禁止池卖单\'];
    if exist(tpdir,'dir') % 直接删除整个目录，新建该目录
        rmdir(tpdir,'s')
        mkdir(tpdir)
    else
        mkdir(tpdir)
    end
    Utilities_zjx.cell2csv([tpdir '卖单金额汇总.csv'],cAccountView)
%     Utilities_zjx.cell2csv([tpdir '个人卖单金额汇总.csv'],table2cell(tAccountView(strcmpi(tAccountView.trader,chTrader),{'id','totsellamt'})))
end

%% 生成交易系统的批量下单
cAccounts = unique(tSellPos.account);
nA = numel(cAccounts);
for iA = 1:nA
    chID = cAccounts{iA};
    if any(strcmpi(cAccounts,[chID,'A']))
        continue
    end
    if any(strcmpi(tInfo.id,chID))
        chTrader = tInfo.trader{strcmpi(tInfo.id,chID)};
    end
    if strcmpi(chTrader,'Lary')
        chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\' cAccounts{iA} '-forbid-' tpcht];
    else
        chFile = ['Z:\' chTrader '\自动禁止池卖单\' cAccounts{iA} '-forbid-' tpcht];
    end
    tOrders = tSellPos(strcmpi(tSellPos.account,chID),:);
    tOrders.qty = -tOrders.sellamt;
    tOrders = tOrders(:,{'windcode','name','account','qty'});
    JStrading.makesellorders(chFile,tOrders);
end

end