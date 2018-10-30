function calAShareReturn(date,modelname)
% calculate the daily return of A stock for "modelname"
% input:
%   date: 日期，可以用字符(yyyymmdd)和数字表示
%   modelname: 计算模型名称
% output
%   insert into DB, no return
% created By Neo - 2018.1.13 

%参数初始化
if ~exist('date','var')
    date=datestr(today,'yyyymmdd');
elseif isnumeric(date)
    date=datestr(date,'yyyymmdd');
end

if ~exist('modelname','var')
    modelname='JASON';
end
s_ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');

jtr=JasperTradingRoom;
%w=windmatlab;
[pos] = getPosition(s_ydate,modelname,jtr);
if isempty(pos)
    return;
end
[pctChg] = getQuotaInfo(date,jtr);
[ret] = calcReturn(pos,pctChg);

fprintf('%s return is : %f\n',date,ret);
conn=jtr.db88conn;
res = Utilities.upsert(conn,'JasperDB.dbo.ASharePerformance',{'Trade_dt','TotalReturn',... %'TotalAsset',
            'modelname'},{'Trade_dt','modelname'},{date,ret*10000,modelname}); 
fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
%w.close;
end

% get the pos of yesterday
function [pos] = getPosition(s_ydate,modelname,jtr)
    conn=jtr.db88conn;
    sqlstr=['SELECT [WindCode],sum([Ratio]) FROM [JasperDB].[dbo].[JasperOtherOrder] where ModelName=''' modelname ...
        ''' and Trade_dt=''' s_ydate ''' group by WindCode;'];
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        warning('%s %s position has not found in DB. \n',s_ydate,modelname);      
        pos=[];
    else    
        pos=cell2table(data,'VariableNames',{'windcodes','ratios'});
    end 
end
%get Quota info
function [pctChg] = getQuotaInfo(s_date,jtr)  
    conn=jtr.db85conn;
    sqlstr=strcat('SELECT a.[S_INFO_WINDCODE],a.[S_DQ_PCTCHANGE]/100 FROM [WINDFILESYNC].[dbo].[ASHAREEODPRICES] a',...
        ' where a.TRADE_DT=''',s_date,''' order by a.S_INFO_WINDCODE;');
    data=Utilities.getsqlrtn(conn,sqlstr);
    if isempty(data)      
        error('(%s): DB prices of %s has not updated.',datestr(now(),0),s_date);        
    else
        pctChg=cell2table(data,'VariableNames',{'windcodes','pctchgs'});     
   end 
end
% calculate daily return
function [ret] = calcReturn(pos,pct) 
    [isin ,rows]=ismember(pos.windcodes,pct.windcodes);   
    pctChgs=pct.pctchgs(rows(isin==1));
    ret=sum(pos.ratios.*pctChgs)/sum(pos.ratios);  
end