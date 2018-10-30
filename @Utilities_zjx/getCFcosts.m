% S20161031 主力合约spread、费用表
function tResult = getCFcosts(dDatenum)
% 
% 
% - by Lary 2016.11.01
%      Lary 2016.11.07 补全历史settle

if nargin == 0
    dDatenum = today-1;
end

gta = GTADB;

tFu = Utilities_zjx.getFuInfoAll2;
tZLHY = gta.getDailyZLHYList(dDatenum);
if ~strcmpi(tZLHY.Properties.VariableNames,'settle')
    w = windmatlab;
    tZLHY.settle = w.wss(Utilities_zjx.getwindcode(tZLHY.ConCode),'settle','tradeDate=20161106','cycle=D');
end
tFu.Code = cellstr(tFu.Code);

tInfo = join(tFu,tZLHY);
dSpreadCost = tInfo.MinUnitChange./tInfo.settle;

dTradeCost = double(tInfo.TCostRatio<0.01).*(tInfo.TCostRatio+tInfo.TCostRatio2)...
    + double(tInfo.TCostRatio>0.01).*(tInfo.TCostRatio+tInfo.TCostRatio2)./tInfo.settle./tInfo.TradingUnit;

tResult.code = tFu.Code;
tResult.name = tFu.Name;
tResult.exchange = tFu.Exchange;
tResult.settle = tInfo.settle;
tResult.minunit = tInfo.MinUnitChange;
tResult.fee = tInfo.TCostRatio + tInfo.TCostRatio2;
tResult.spreadratio = dSpreadCost;
tResult.feeratio = dTradeCost;
tResult.costratio = dSpreadCost + dTradeCost;
tResult = struct2table(tResult);

end