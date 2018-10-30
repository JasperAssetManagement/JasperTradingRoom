function output = curveanalysis(dNav,dDates,dPos,varargin)
%% curveanalysis用于对净值曲线进行分析。
% totrtn
% std
% MD
% sharpe
% Winrate
% MeanRtn
% WinRtn
% LossRtn
% Odd
% RE

% warning('本函数未完成。\n')

dRiskfree = 0.00;

if dNav(1) > 1.1 || dNav(1) < 0.9
    dNav = dNav/dNav(1);
end

bDate = exist('dDates','var');
bPos = exist('dPos','var');
bPlot = any(strcmpi(varargin,'plot'));

nDates = numel(dNav);
dMD = zeros(nDates,1);
tpMax = dNav(1);
dRtns = diff(log([1; dNav]));
for iDate = 1:nDates
    tpMax = max(tpMax,dNav(iDate));
    dMD(iDate) = 1-dNav(iDate)/tpMax;
end

if bDate
    output.start = str2double(datestr(dDates(1),'yyyymmdd'));
    output.end = str2double(datestr(dDates(end),'yyyymmdd'));
    output.totrtn = dNav(end)/dNav(1)-1;
    output.alzdrtn = (output.totrtn + 1)^(365/(dDates(end)-dDates(1)))-1;
    output.alzdvol = std(dRtns)*sqrt(numel(dDates)*365/(dDates(end)-dDates(1)));
    output.md = max(dMD);
    output.sharpe = (output.alzdrtn - dRiskfree)/output.alzdvol;
%     output.sharpe = mean(dRtns)*250/output.alzdvol;
else
    output.totrtn = dNav(end)/dNav(1)-1;
    output.alzdrtn = (output.totrtn + 1)^(250/numel(dNav))-1;
    output.alzdvol = std(dRtns)*sqrt(250);
    output.md = max(dMD);
%     output.sharpe = (output.alzdrtn - dRiskfree)/output.alzdvol;
    output.sharpe = mean(dRtns)*250/output.alzdvol;
end
% output.mdseq = dMD;

if bPos
    output.ntrades = sum(dPos~=0);
    output.nlong = sum(dPos>0);
    output.nshort = sum(dPos<0);
    output.winrate = sum(dRtns>0)/output.ntrades;
    output.winrate_long = sum(dRtns>0 & dPos>0)/output.nlong;
    output.winrate_short = sum(dRtns>0 & dPos<0)/output.nshort;
    output.meanrtn = sum(dRtns)/output.ntrades;
else
    output.winrate = sum(dRtns>0)/sum(dRtns~=0);
    output.ntrades = sum(dRtns~=0);
    output.meanrtn = mean(dRtns)/sum(dRtns~=0);
end

output.meanrtn_win = mean(dRtns(dRtns>0));
output.meanrtn_loss = mean(dRtns(dRtns<0));
output.odd = -output.meanrtn_win/output.meanrtn_loss;
output.er = output.alzdrtn/output.md;

if bPlot
    if bDate
        subplot(2,1,1)
        plot(dDates,dNav)
        datetick('x','keeplimits')
        subplot(2,1,2)
        area(dDates,-dMD)
        datetick('x','keeplimits')
    else
        subplot(2,1,1)
        plot(dNav)
        subplot(2,1,2)
        area(-dMD)
    end
end

end