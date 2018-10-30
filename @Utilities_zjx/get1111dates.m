function dDates = get1111dates(dDate)
% 获取历史双11前后交易日。
% 
% - by Lary 2016.11.10

if nargin == 0
    dDate = today;
end

if month(dDate)>11
    dEnd = year(dDate);
else
    dEnd = year(dDate)-1;
end
dStart = 2011;

dDates = [];

for iYear = dStart:dEnd
    tpDate = datenum(iYear,11,11);
    tpStart = Utilities_zjx.tradingdate(tpDate,-30);
    tpEnd = Utilities_zjx.tradingdate(tpDate,30);
    tpDates = Utilities_zjx.tradingdate([],[],'start',tpStart,'end',tpEnd);
    dDates = cat(1,dDates,tpDates);
end

end