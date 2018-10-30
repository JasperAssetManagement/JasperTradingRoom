function [] = initTradingDates(firstY,lastY,market)
% 输入：
%       dFirstY:    需要更新的起始年份
%       dLastY:     需要更新的最后年份
%       sMarket:    可选择只更新某个市场 SZ,SH,HK(HKEX),NY(NYSE)
%  使用windmatlab接口,
% 例子：
%      Utilities.initTradingDates(2001,2007); 
%               更新2001到2007所有市场的交易日。
%      Utilities.initTradingDates();
%               更新20010101(default first day)到今年年底所有市场的交易日。
%      Utilities.initTradingDates(2001,2007,'HK');
%               更新2001到2007香港市场的交易日 
%
% - by Neo 2017.09.21
% set default value
sMarket   = {'SZ' 'SH' 'HK' 'NY'};
dLastday  = today; 
marketDict = genMarketDict;

if nargin == 0
    dFirstday = 730852; %default first day:2001-01-01     
elseif nargin == 1
    if isa(firstY,'numeric')
        firstY=num2str(firstY);
    end
    dFirstday = datenum([firstY '-01-01']); 
elseif nargin >= 2
    if isa(firstY,'numeric')
        firstY=num2str(firstY);
    end
    dFirstday = datenum([firstY '-01-01']); 
    if isa(lastY,'numeric')
        lastY=num2str(lastY);
    end
    dLastday = datenum([lastY '-12-31']);     
end
if nargin == 3
    sMarket = upper(market);
end

try
    w=windmatlab;
    for ii=1 : numel(sMarket)
        if ~isKey(marketDict,sMarket{ii})
            error('initTradingDates:InvalidInput','Do not match the market: %s',sMarket{ii});
        else
            if ~strcmp(sMarket{ii},'SZ') && ~strcmp(sMarket{ii},'SH')
                w_datas=w.tdays(dFirstday,dLastday,['TradingCalendar=' marketDict(sMarket{ii})]);
            else
                w_datas=w.tdays(dFirstday,dLastday);
            end        
            TradingDates.(sMarket{ii}) = datenum(w_datas);            
        end
    end
    w.close
catch err
    w.close;  
    error(err.identifier,err.message);
end
save('TradingDates.mat','TradingDates');
end

function marketDict = genMarketDict()
%维护市场代码
    marketDict = containers.Map;
    marketDict('SZ')='SZ';
    marketDict('SH')='SH';
    marketDict('HK')='HKEX';
    marketDict('NY')='NYSE';    
end