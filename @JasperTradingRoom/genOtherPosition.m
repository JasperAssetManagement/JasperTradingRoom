function []=genOtherPosition(date)
% 根据昨日持仓和今日交易生成date日的other position的仓位 
% 输入：
%       date: 输入日期,matlab整数型日期或者 'yyyymmdd'字符串型
% 例: JasperTradingRoom.genOtherPosition
% - Created by Neo 2017.11.21
% - Modified by Neo 2018.04.20

jtr=JasperTradingRoom;
w=windmatlab;

if ( nargin==0 )
    date=datestr(today(),'yyyymmdd');
elseif ( isnumeric(date) )
    date=datestr(date,'yyyymmdd');
end
ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');

%清除已生成持仓
conn=jtr.db88conn;
sql=['delete from [JasperDB].[dbo].[JasperOtherPosition] where Trade_dt=''' date ''';'];
Utilities.execsql(conn,sql);

% 更新OtherOrder(%)
% conn=jtr.db88conn;
% sql=['SELECT [WindCode],sum([Ratio]),[ModelName],[AccType] FROM [JasperDB].[dbo].[JasperOtherOrder]' ...
%     ' where Trade_dt=''' date ''' group by [WindCode],[ModelName],[AccType];'];
% torder=Utilities.getsqlrtn(conn,sql);
% if ~isempty(torder)    
%     torder=cell2table(torder,'VariableNames',{'windcode','ratio','modelname','acctype'});
%     torder.close=w.wsd(torder.windcode,'close',ydate,ydate);
%     torder.name=w.wsd(torder.windcode,'sec_name',date,date);
%     
%     cAccs=jtr.getaccounts;
%     acctypes=unique(torder.acctype);
%     for i=1:length(acctypes)
%         rows=torder.acctype==acctypes(i);
%         updateOtherPos(acctypes(i),cAccs,jtr, torder.windcode(rows),torder.name(rows),torder.ratio(rows),torder.close(rows),torder.modelname(rows),date)
%     end  
% end

% 根据OtherOrderByQty更新pos
conn=jtr.db88conn;
sql=['SELECT [Account],[WindCode],[Qty],[ModelName],[Type] FROM [JasperDB].[dbo].[JasperOtherOrderByQty]' ...
    ' where Trade_dt=''' date ''';'];
torder=Utilities.getsqlrtn(conn,sql);
tradeflag=false;
if ~isempty(torder)    
    torder=cell2table(torder,'VariableNames',{'account','windcode','trade_qty','modelname','type'});
    tradeflag=true;
end

% 昨日持仓
conn=jtr.db88conn;
sql=['SELECT [Account],[WindCode],[Qty],[ModelName],[Type] FROM [JasperDB].[dbo].[JasperOtherPosition]' ...
    ' where Trade_dt=''' ydate ''';'];
tpos=Utilities.getsqlrtn(conn,sql);
posflag=false;
if ~isempty(tpos)
    tpos=cell2table(tpos,'VariableNames',{'account','windcode','qty','modelname','type'});
    posflag=true;
end

if posflag
    if tradeflag
        tpos=outerjoin(tpos,torder,'MergeKeys',1);
        tpos.qty(isnan(tpos.qty))=0;
        tpos.trade_qty(isnan(tpos.trade_qty))=0;
        tpos.qty=tpos.qty+tpos.trade_qty;
        tpos(tpos.qty==0,:)=[];
        tpos.trade_qty=[];
    end
elseif tradeflag
    tpos=torder;
    tpos.qty=tpos.trade_qty;
    tpos.trade_qty=[];
end
if ~isempty(tpos) %如果清仓则不处理
    tpos.trade_dt=repmat({date},size(tpos,1),1);   
    tpos.side=repmat({1},size(tpos,1),1);
    codes=unique(tpos.windcode);
    names=w.wss(codes,'sec_name');
    tpos.name=cellfun(@(x) names(strcmp(x,codes)==1),tpos.windcode);

    conn=jtr.db88conn;
    res=Utilities.upsert(conn,'JasperDB.dbo.JasperOtherPosition',tpos.Properties.VariableNames,[1 1 0 1 0 1 0 0 0],table2cell(tpos));
    fprintf('upsert OtherPosition(from otherOrderByQty):insert %d,update %d \n',sum(res==1),sum(res==0));      
end
conn=jtr.db88conn;
sql=['update JasperDB.dbo.JasperOtherPosition set account=''5B'' where account=''05'' and trade_dt =''' date ''';'];
Utilities.execsql(conn,sql);

w.close;
end

% function [] = updateOtherPos(acctype,cAccs,jtr, windcode,name,ratio,close,modelname,date)
% cTarAcc=jtr.getAccInfo(acctype);
%   
% [isin,rows]=ismember(cTarAcc,cAccs.ids);
% dAccAssets=cAccs.AShareAmounts(rows(isin==1));   
% %dAccAssets=cAccs.assets(rows(isin==1));   
% 
% func=@(x,y) arrayfun(@(k,l,m,n,o) [y,k,l,round(x*m/n,-2),o],windcode,name,ratio,close,modelname,'un',0);
% tpos=arrayfun(func,dAccAssets,cTarAcc,'un',0);
% 
% func=@(x) cat(1,x{:});
% tpos=arrayfun(@(x) func(tpos{x}),1:size(tpos,1),'un',0);
% tpos=cat(1,tpos{:});
% 
% tpos=cell2table(tpos,'VariableNames',{'account','windcode','name','qty','modelname'});
% tpos.trade_dt=repmat({date},size(tpos,1),1);
% tpos.type=repmat({'S'},size(tpos,1),1);
% tpos.side=repmat({1},size(tpos,1),1);
% tpos(tpos.qty==0,:)=[];
% 
% conn=jtr.db88conn;
% res=Utilities.upsert(conn,'JasperDB.dbo.JasperOtherPosition',tpos.Properties.VariableNames,[1 1 0 0 1 1 0 0],table2cell(tpos));
% fprintf('upsert OtherPosition(from otherOrder):insert %d,update %d \n',sum(res==1),sum(res==0)); 
% end

