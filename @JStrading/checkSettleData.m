function tOut = checkSettleData(chDate)
% checkSettleData 持仓记录和成交记录的轧差验算。
%
% - by Lary 2017.06.13

if exist('chDate','var')
    dtodayt = datenum(chDate,'yyyymmdd');
    dyst = Utilities_zjx.tradingdate(dtodayt,-1);
    dyst2 = Utilities_zjx.tradingdate(dtodayt,-2);
    chYstDate = datestr(dyst,'yyyymmdd');
    chYstDate2 = datestr(dyst2,'yyyymmdd');
else
    dtodayt = Utilities_zjx.tradingdate(today);
    dyst = Utilities_zjx.tradingdate(dtodayt,-1);
    dyst2 = Utilities_zjx.tradingdate(dtodayt,-2);
    chDate = datestr(dtodayt,'yyyymmdd');
    chYstDate = datestr(dyst,'yyyymmdd');
    chYstDate2 = datestr(dyst2,'yyyymmdd');
end

jst = JStrading;
tPosition1 = jst.getJasperPosition(chDate);
if isempty(tPosition1)
    error('今日持仓尚未导入。')
end

tPosition2 = jst.getJasperPosition(chYstDate);
tPosition1 = tPosition1(:,{'windcode','account','qty'});
tPosition2 = tPosition2(:,{'windcode','account','qty'});

tTrading = jst.getTradeDetail(chDate);
tPosition1.windcode = upper(tPosition1.windcode);
tPosition2.windcode = upper(tPosition2.windcode);
tTrading.windcode = upper(tTrading.windcode);
tTrading.side = str2double(tTrading.side);
tTrading.dealqty(tTrading.side==2) = -tTrading.dealqty(tTrading.side==2);

% tTrading.dealqty(strcmpi(tTrading.type,'FU')) = -tTrading.dealqty(strcmpi(tTrading.type,'FU'));
bNonCash = ~strcmpi(tTrading.type,'C');
tTrading = tTrading(bNonCash,:);

cAccounts = unique(union(tPosition1.account,tPosition2.account));
cAccounts = setdiff(cAccounts,{'67'});
nAccounts = numel(cAccounts);
tOut = [];
for iA = 1:nAccounts
    tpAccount = cAccounts{iA};
    if isnan(str2double(tpAccount)) % 不考虑分仓的交易。
        continue
    end
    tppos1 = tPosition1(strcmpi(tPosition1.account,tpAccount),:);
    tppos2 = tPosition2(strcmpi(tPosition2.account,tpAccount),:);

    tptrade = tTrading(strcmpi(tTrading.account,tpAccount),:);
    if ~isempty(tptrade)
        cTradeS = Utilities_zjx.pivottable(table2cell(tptrade),2,6,@sum);
        tpttrade = cell2table(cTradeS,'VariableNames',{'windcode','dealqty'});
    else
        tpttrade = cell2table(cell(0,2),'VariableNames',{'windcode','dealqty'});
    end

    tppos1.Properties.VariableNames{strcmpi(tppos1.Properties.VariableNames,'qty')} = 'todayqty';
    tppos2.Properties.VariableNames{strcmpi(tppos2.Properties.VariableNames,'qty')} = 'lastqty';

    tppos1 = tppos1(:,{'windcode','todayqty'});
    tppos2 = tppos2(:,{'windcode','lastqty'});

    tsumm = outerjoin(tppos1,tppos2);
    tpBad = cellfun(@(x)isempty(x),tsumm.windcode_tppos1);
    tsumm.windcode_tppos1(tpBad) = tsumm.windcode_tppos2(tpBad);
    tsumm = tsumm(:,{'windcode_tppos1','todayqty','lastqty'});
    tsumm.Properties.VariableNames = {'windcode','todayqty','lastqty'};
    if ~isempty(tptrade)
        tsumm = outerjoin(tsumm,tpttrade);
        tpBad = cellfun(@(x)isempty(x),tsumm.windcode_tsumm);
        tsumm.windcode_tsumm(tpBad) = tsumm.windcode_tpttrade(tpBad);
    else
        tsumm.dealqty = zeros(numel(tsumm.windcode),1);
        tsumm.windcode_tsumm = tsumm.windcode;
    end
    tsumm.dealqty(isnan(tsumm.dealqty)) = 0;
    tsumm.todayqty(isnan(tsumm.todayqty)) = 0;
    tsumm.lastqty(isnan(tsumm.lastqty)) = 0;
    bBad = (tsumm.lastqty + tsumm.dealqty ~= tsumm.todayqty);
    if any(bBad)
        tpt = tsumm(bBad,{'windcode_tsumm','todayqty','lastqty','dealqty'});
        tpt.Properties.VariableNames = {'windcode','todayqty','lastqty','dealqty'};
        tpt.account = repmat({tpAccount},sum(bBad),1);
        tOut = cat(1,tOut,tpt);
    end
end

cDivCodes = jst.getsqlrtn(jst.irdbconn,['select wind_code from windfilesync.dbo.asharedividend where ex_dt > ' chYstDate2 ' and stk_dvd_per_sh> 0']);

bGood = cellfun(@(x)any(strcmpi(x(1:3),{'601','600','300','002','000','IF1','IH1','IC1'})),tOut.windcode);

bGood3 = cellfun(@(x)any(strcmpi(x(end-2:end),{'.HK'})),tOut.windcode);
bGood2 = ~ismember(tOut.windcode,cDivCodes); % 对于发生分红除权的股票，暂不检查正确性。

tOut = tOut((bGood|bGood3)&bGood2,:);

end