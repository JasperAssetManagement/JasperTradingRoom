function [datesOut] = tradingdate(dToday,dSteps,varargin)
% 输入：
%       dToday:     输入日期,matlab整数型日期
%       nLags:      偏移量,正整数或负整数，用于向前或向后调整交易日。
%       varargin:   可变输入，主要用于控制是否输出一列交易日。
% 
% 输出：
%       datesOut：交易日
%  varargin :
%  start  : 起始日期，可以用字符(yyyy-mm-dd)和数字表示
%  end    : 结束日期，可以用字符(yyyy-mm-dd)和数字表示
%  market : 获取对应的市场 （SH,SZ,HK)
%  outputStyle : 输出指定格式字符型的日期
% 例子：
%      dLastTradingDate = Utilities.tradingdate(today,-1); 
%               返回today以前的最近一个交易日。
%      dClosestTradingDate = Utilities.tradingdate(today,0);
%               如果today是交易日则返回today,否则返回today最近的前交易日。
%      dNextTradingDate = Utilities.tradingdate(today,1);
%               返回today以后的下一个交易日。
%      dDates = Utilities.tradingdate(1,1,'start','2016-01-01','end','2016-06-30');
%               获取2016年1月1日到6月30日之间的所有交易日
%      dDates = Utilities.tradingdate([],0,'start',735965,'end',736330,'market','HK','outputStyle','yyyymmdd');
%               获取735965到736330之间的HK市场所有交易日，以字符(yyyymmdd)格式返回
%      dDates = Utilities.tradingdate([],nan,'start',735965);
%               获取735965到今天之间的所有交易日      
%
% - by Neo 2017.09.20
if ~exist('TradingDates','var')
    load('TradingDates.mat');
end
% set default value
if nargin == 0
    dToday = today;
    dSteps = 0;
elseif nargin == 1
    dSteps = 0;
end
if isempty(dToday)
    dToday = today;
end
if isa(dToday,'char')
    dToday = datenum(dToday);
end
p.start    = [];
p.end      = [];
p.market   = 'SZ';
p.outputStyle = [];

validParams     = {     ...
  'start',       ...
  'end',         ...
  'market',      ...
  'outputStyle'  ...
  };

if nargin > 3
    if mod( numel( varargin ), 2 ) ~= 0
        error( 'tradingdate:InvalidInput', ['All input parameters after the nLaps must be in the ' ...
         'form of param-value pairs'] );
    end
    params = varargin(1:2:end);
    values = varargin(2:2:end);
    
    if ~all( cellfun( @ischar, params ) )
        error( 'tradingdate:InvalidInput', 'All input parameters after the nLaps must be chars');
    end
    
    for ii =  1 : numel( params )
        result = strcmpi( params{ii}, validParams );
        %If unknown param is entered ignore it
        if sum( result ) == 0
          continue
        end
        %If we have multiple matches make sure we don't have a single unambiguous match before throwing
        %an error
        if sum( result ) > 1
            exresult = strcmp( params{ii}, validParams );
            if sum( exresult ) == 1
                result = exresult;
            else
                %We have multiple possible matches, prompt user to provide an unambiguous match
                error( 'tradingdate:InvalidInput', 'Cannot find unambiguous match for parameter ''%s''', ...
                    varargin{ii*2-1} );
            end
        end
        result      = validParams{result};
        p.(result)  = values{ii};
    end
end

%choose the trading dates of the market,default SZ
dDateList=TradingDates.(p.market);

%If has a start date and end date
if ~isempty(p.start)
    if isa(p.start,'char')
        p.start=datenum(p.start);
    end
    if ~isempty(p.end)
        if isa(p.start,'char')
            p.end=datenum(p.end);
        end
    else
        p.end=today; %If we only have the start date, we set the end date = today
    end
    dStartRows=find(dDateList>=p.start);
    dEndRows=find(dDateList<=p.end);
    dStartRows=dStartRows(1);    
    dEndRows=dEndRows(end);
    datesOut=dDateList(dStartRows:dEndRows);
else
    dToday = fix(dToday);
    dSteps = fix(dSteps);
    dRows=find(dDateList<=dToday); %If today is not a trading day, choose the pre trading date
    datesOut=dDateList(dRows(end)+dSteps);
end

if ~isempty(p.outputStyle)
    datesOut=datestr(datesOut,p.outputStyle);
end
    
end