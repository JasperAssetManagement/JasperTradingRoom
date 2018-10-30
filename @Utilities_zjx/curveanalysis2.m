function dOutput = curveanalysis2(dNavs)
%% curveanalysis2用于对多条净值曲线进行分析。
% 输出为double矩阵
% - by Lary 2016.09.19

if isempty(dNavs)
    dOutput = [];
    return
end

nStocks = size(dNavs,2);

dOutput = [];

for iStock = 1:nStocks
    dNav = dNavs(:,iStock);
    nDates = numel(dNav);
    dMD = zeros(nDates,1);
    tpMax = dNav(1);
    dRtns = diff(log([1; dNav]));
    for iDate = 1:nDates
        tpMax = max(tpMax,dNav(iDate));
        dMD(iDate) = 1-dNav(iDate)/tpMax;
    end

    tps.totrtn = dNav(end)/dNav(1)-1;
    tps.alzdrtn = (tps.totrtn + 1)^(250/numel(dNav))-1;
    tps.alzdvol = std(dRtns)*sqrt(250);
    tps.md = max(dMD);
    tps.sharpe = (tps.alzdrtn - 0.00)/tps.alzdvol;

    tps.winrate = sum(dRtns>0)/sum(dRtns~=0);
    tps.ntrades = sum(dRtns~=0);
    tps.meanrtn = mean(dRtns)/sum(dRtns~=0);

    tps.meanrtn_win = mean(dRtns(dRtns>0));
    tps.meanrtn_loss = mean(dRtns(dRtns<0));
    tps.odd = -tps.meanrtn_win/tps.meanrtn_loss;
    tps.er = tps.alzdrtn/tps.md;
    
    dOutput = cat(2,dOutput,cell2mat(struct2cell(tps)));
end

end