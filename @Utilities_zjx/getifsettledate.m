function nDate = getifsettledate(nYear,nMonth)
% 获取股指期货某月的交割日
if nargin==0
    nYear = year(today);
    nMonth = month(today);
end
if isnan(nMonth)||isnan(nYear)
    nDate = NaN;
    return
end
nDay = 1;
nFridays = 0;
while nFridays~=3
    nDate = datenum(nYear,nMonth,nDay);
    bFriday = weekday(nDate)==6;
    nFridays = nFridays + double(bFriday);
    nDay = nDay + 1;
end
end