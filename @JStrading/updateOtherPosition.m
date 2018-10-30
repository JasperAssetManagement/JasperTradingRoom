function updateOtherPosition()
%% 根据OtherOrders表计算出每个产品每个策略下的理论持仓

w = windmatlab;
jst = JStrading;
zjx = Utilities_zjx;

dVolLimitRatio = 0.1; % 合计卖出量占过去10日日均成交量的10%

conn = jst.dbconn;

tped = Utilities_zjx.tradingdate(today-1);
tptd = Utilities_zjx.tradingdate(tped,1);
tpsd = Utilities_zjx.tradingdate(tped,-10);
tpche = datestr(tped,'yyyymmdd');

tpcht = datestr(tptd,'yyyymmdd');
tpchs = datestr(tpsd,'yyyymmdd');

sqlState = 'select trade_dt,windcode,name,ratio,modelname from JasperDB.dbo.JasperOtherOrder  where trade_dt = ';
sqlState = [sqlState '''' datestr(tptd,'yyyymmdd') ''''];

tInputs = jst.getsqlrtn(conn,sqlState);
tInputs = cell2table(tInputs,'VariableNames',{'trade_dt','windcode','name','weight','modelname'});
tClose = cell2table(unique(tInputs.windcode),'VariableNames',{'windcode'});
tClose.close = w.wss(tClose.windcode,'close');
tInputs = join(tInputs,tClose);

sqlState = 'select account,totalasset from [JasperDB].dbo.accountdetail  where trade_dt = ';

conn = jst.dbconn;
sqlState = [sqlState '''' datestr(tped,'yyyymmdd') ''''];
cData = jst.getsqlrtn(conn,sqlState);
tAssets = cell2table(cData,'VariableNames',{'account','totalasset'});
tAssets.buyamt = fix(tAssets.totalasset*sum(tInputs.weight));


tInfo = JStrading.getforbidinfo;
% tInfo = tInfo(strcmpi(tInfo.trader,'Lary'),:);
tInfo.account = tInfo.id;
tInfo = innerjoin(tInfo,tAssets);
cBan = {'15','37','45','68','04','20','32','22','17','50','47'};
tInfo = tInfo(~ismember(tInfo.account,cBan),:);

tAssets = innerjoin(tAssets,tInfo);

dTotalAUM = sum(tAssets.totalasset);
tpAvgAmt = w.wss(tInputs.windcode,'avg_amt_per','unit=1',['startDate=' tpchs],['endDate=' tpche]);
tpAvgAmt = tpAvgAmt*dVolLimitRatio;
tpBuyAmt = dTotalAUM.*tInputs.weight;
tpRatio = tpBuyAmt./tpAvgAmt;
tpRatio(tpRatio<1) = 1;
tInputs.weight = tInputs.weight./tpRatio;

nAccounts = numel(tAssets.totalasset);
nStocks = numel(tInputs.windcode);
tOtherPosisition = [];
cAccounts = tInfo.account;

for iA = 1:nAccounts
    chAccount = tInfo.account{iA};
    dAsset = tAssets.totalasset(iA);
    tOrders = tInputs;
    tOrders.account = repmat({chAccount},nStocks,1);
    tOrders.qty = round(dAsset.*tOrders.weight./tOrders.close/100)*100;
    tOrders = tOrders(:,{'trade_dt','windcode','name','account','qty','modelname'});
    tOtherPosisition = cat(1,tOtherPosisition,tOrders);
end
tOtherPosisition.side = ones(size(tOtherPosisition.qty));
% sqlState = ['delete top(2000000) from JasperDB.dbo.JasperOtherPosition where Trade_dt=''' tpcht ''''];
sqlState = ['delete from JasperDB.dbo.JasperOtherPosition where Trade_dt=''' tpcht ''''];
a1 = jst.getsqlrtn(jst.dbconn,sqlState);
datainsert(jst.dbconn,'[JasperDB].[dbo].[JasperOtherPosition]',tOtherPosisition.Properties.VariableNames,table2cell(tOtherPosisition));

close(conn)
end