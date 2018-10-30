function [datesOut] = tradingdate(dToday,dSteps,varargin)
% ���룺
%       dToday:     ��������,matlab����������
%       nLags:      ƫ����,��������������������ǰ�������������ա�
%       varargin:   �ɱ����룬��Ҫ���ڿ����Ƿ����һ�н����ա�
% 
% �����
%       datesOut��������
%  varargin :
%  start  : ��ʼ���ڣ��������ַ�(yyyy-mm-dd)�����ֱ�ʾ
%  end    : �������ڣ��������ַ�(yyyy-mm-dd)�����ֱ�ʾ
%  market : ��ȡ��Ӧ���г� ��SH,SZ,HK)
%  outputStyle : ���ָ����ʽ�ַ��͵�����
% ���ӣ�
%      dLastTradingDate = Utilities.tradingdate(today,-1); 
%               ����today��ǰ�����һ�������ա�
%      dClosestTradingDate = Utilities.tradingdate(today,0);
%               ���today�ǽ������򷵻�today,���򷵻�today�����ǰ�����ա�
%      dNextTradingDate = Utilities.tradingdate(today,1);
%               ����today�Ժ����һ�������ա�
%      dDates = Utilities.tradingdate(1,1,'start','2016-01-01','end','2016-06-30');
%               ��ȡ2016��1��1�յ�6��30��֮������н�����
%      dDates = Utilities.tradingdate([],0,'start',735965,'end',736330,'market','HK','outputStyle','yyyymmdd');
%               ��ȡ735965��736330֮���HK�г����н����գ����ַ�(yyyymmdd)��ʽ����
%      dDates = Utilities.tradingdate([],nan,'start',735965);
%               ��ȡ735965������֮������н�����      
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