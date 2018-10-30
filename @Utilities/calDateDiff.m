function [ cnts ] = calDateDiff( startDate,endDate,varargin )
%CALDATEDIFF 计算日期间隔
%   startDate: 起始日, 支持数字和'yymmmmd'格式的字符串
%   endDate: 结束日, 支持数字和'yymmmmd'格式的字符串
%   varargin
%      type: tradedate 以交易日计算 | nature 以自然日计算
%      market: 'SZ,SH,HK,NY' 按某市场计算交易日
% 例子:

% - by Neo 2017.09.20

if ~exist('TradingDates','var')
    load('TradingDates.mat');
end
% set default value
if ischar(startDate) && numel(regexp(startDate,'\d{4}(0[1-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1])'))==1
    d_sdate=datenum(startDate,'yyyymmdd');
else
    error( 'calDateDiff:InvalidInput', ['Input Start Date must be CHAR ,in the ' ...
         'form of ''yyyymmdd'' and in the correct RANGE'] );
end
if ischar(endDate) && numel(regexp(endDate,'\d{4}(0[1-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1])'))==1
    d_edate=datenum(endDate,'yyyymmdd');
else
    error( 'calDateDiff:InvalidInput', ['Input End Date must be CHAR ,in the ' ...
         'form of ''yyyymmdd'' and in the correct RANGE'] );
end
if d_sdate>d_edate
    error( 'calDateDiff:InvalidInput', 'Input End Date must ''>'' Start Date ' );
end
p.type    = 'nature';
p.market   = 'SZ';

validParams     = {     ...
  'type',       ...
  'market'      ...
  };

if nargin > 3
    if mod( numel( varargin ), 2 ) ~= 0
        error( 'calDateDiff:InvalidInput', ['All input parameters after the nLaps must be in the ' ...
         'form of param-value pairs'] );
    end
    params = varargin(1:2:end);
    values = varargin(2:2:end);
    
    if ~all( cellfun( @ischar, params ) )
        error( 'calDateDiff:InvalidInput', 'All input parameters after the endDate must be chars');
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
                error( 'calDateDiff:InvalidInput', 'Cannot find unambiguous match for parameter ''%s''', ...
                    varargin{ii*2-1} );
            end
        end
        result      = validParams{result};
        p.(result)  = values{ii};
    end
end

if strcmp(p.type,'nature')
    cnts = d_edate-d_sdate;
elseif strcmp(p.type,'trade')
    %choose the trading dates of the market,default SZ
    dDateList=TradingDates.(p.market);
    dStartRows=find(dDateList>=d_sdate);
    dEndRows=find(dDateList<=d_edate);
    dStartRows=dStartRows(1);    
    dEndRows=dEndRows(end);
    cnts=dEndRows-dStartRows;
else
    error( 'calDateDiff:InvalidInput', 'unknown value ''%s'' for parameter [type]', p.type );
end

end

