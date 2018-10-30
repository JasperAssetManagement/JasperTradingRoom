function [ flag ] = isTradingDates( date,market )
% 判断data是否为交易日
%   input
%       date:输入的日期，支持数值型和字符型（yyyymmdd)
%       market:按哪个市场的交易日进行查询
%   output
%       flag:1 是交易日；0 非交易日
if ~exist('date','var')
    date=today();
end
if ~isnumeric(date)
    date=datenum(date,'yyyymmdd');
end

if ~exist('market','var')
    market='SZ';
end

if Utilities.tradingdate(date,0,'market',market)==date
    flag=1;
else
    flag=0;
end
end

