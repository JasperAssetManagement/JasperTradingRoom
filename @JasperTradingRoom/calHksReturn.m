function calHksReturn( date )
% calculate the daily return of hk stock for Jason Jiang
% input:
%   date: 日期，可以用字符(yyyymmdd)和数字表示
% output
%   insert into DB, no return
% updated By Neo - 2018.1.13 
jtr=JasperTradingRoom;
if (nargin == 0)
    date=today;    
elseif (nargin == 1)
    if isnumeric(date)
        date=datestr(date,'yyyymmdd');
    end
end
s_ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
hks_ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd','market','HK');
[pos] = getPosition(s_ydate,jtr);
[hkPct] = getQuotaInfo(date);
[ret] = calcReturn(pos,hkPct);

volData=[];
for i=1:size(ret.accounts,1)
    % default net value = 1, then update nv=yestNV*(1+total return)
    volData=[volData; {date},ret.accounts(i),{ret.totalReturn(i)*100},{1*(1+ret.totalReturn(i)/100)}];
end

    conn=jtr.db88conn;
    res = Utilities.upsert(conn,'JasperDB.dbo.HKAccountPerformance',{'Trade_dt','Account',... %'TotalAsset',
            'TotalReturn','NetValue'},{'Trade_dt','Account'},volData); 
    fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));

    %udpate net value
    conn=jtr.db88conn;
    sqlstr=['UPDATE [JasperDB].[dbo].[HKAccountPerformance] SET [NetValue] = (1+[JasperDB].[dbo].[HKAccountPerformance].TotalReturn/10000)*b.netValue ' ...
        'FROM [JasperDB].[dbo].[HKAccountPerformance], [JasperDB].[dbo].[HKAccountPerformance] b ' ...
        'WHERE [JasperDB].[dbo].[HKAccountPerformance].Account=b.account ' ...
        'and [JasperDB].[dbo].[HKAccountPerformance].Trade_dt=''' date ''' and b.Trade_dt=''' hks_ydate ''';'];
    Utilities.execsql(conn,sqlstr);
end    

% get the pos of yesterday
function [pos] = getPosition(s_ydate,jtr)
    conn=jtr.db88conn;
    sqlstr=strcat('select account,WindCode,SUM(qty),ClosePrice from JasperDB.dbo.JasperPosition where Type=''HKS''',32, ...
        'and Trade_dt=''',s_ydate,''' group by Trade_dt,account,WindCode,Name,ClosePrice;');
    data=Utilities.getsqlrtn(conn,sqlstr);
    if size(data)<=0
        fprintf('Error(%s): %s hk position has not found in DB. \n',datestr(now(),0),s_ydate);      
    else    
        pos.accounts=data(:,1);
        pos.codes=data(:,2);
        pos.qtys=cell2mat(data(:,3));        
        pos.closeprices=cell2mat(data(:,4));        
    end 
end
%get Quota info
function [hkPct] = getQuotaInfo(s_date)   
    root_path = '\\192.168.1.88\Trading Share\daily_quote\';
    hkPct=readtable([root_path 'hkstock_' s_date '.csv']);
end
% calculate daily return
function [ret] = calcReturn(pos,hkPct)
    accounts=unique(pos.accounts);
    ret.accounts=accounts;
    ret.totalReturn=zeros(length(accounts),1);
  
    for i=1:length(accounts)
        fprintf('Info(%s):Deal with the account: %s \n',datestr(now(),0),accounts{i});
        rows=strcmp(pos.accounts,accounts{i})==1;
        codes=pos.codes(rows); 
        qtys=pos.qtys(rows); 
        [isin ,rows]=ismember(codes,hkPct.symbol); 
        preCloses=hkPct.pre_close(rows(isin==1));
        pctChgs=hkPct.change_rate(rows(isin==1));
        ratios=(qtys.*preCloses)/sum(qtys.*preCloses);
        ret.totalReturn(i)=sum(ratios.*pctChgs);        
    end    
end