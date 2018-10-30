function [] = initTradingDates(firstY,lastY,market)
% ���룺
%       dFirstY:    ��Ҫ���µ���ʼ���
%       dLastY:     ��Ҫ���µ�������
%       sMarket:    ��ѡ��ֻ����ĳ���г� SZ,SH,HK(HKEX),NY(NYSE)
%  ʹ��windmatlab�ӿ�,
% ���ӣ�
%      Utilities.initTradingDates(2001,2007); 
%               ����2001��2007�����г��Ľ����ա�
%      Utilities.initTradingDates();
%               ����20010101(default first day)��������������г��Ľ����ա�
%      Utilities.initTradingDates(2001,2007,'HK');
%               ����2001��2007����г��Ľ����� 
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
%ά���г�����
    marketDict = containers.Map;
    marketDict('SZ')='SZ';
    marketDict('SH')='SH';
    marketDict('HK')='HKEX';
    marketDict('NY')='NYSE';    
end