function genBoothbayPosition(date, accId)
% ÿ���̺�����Boothbay�ĳֲ֣��������յĳֲֺͽ��յĽ������ɣ������յĳֲ���Ҫ���зֺ��͹ɴ���
% input:     
% date:      ���ڣ�֧��yyyymmdd���ͺ���������
% ��: JasperTradingRoom.genBoothbayPosition(today())
% by Neo - 2017.11.29 
jtr = JasperTradingRoom;

if exist('date','var')
    if isnumeric(date)
        date=datestr(date,'yyyymmdd');
    end
else
    date=datestr(today(),'yyyymmdd');
end
ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
w=windmatlab;
%1.0 ȡPos(JasperPositionNew���Ѿ�������͹ɵĳֲ�����
conn=jtr.db88conn;
sql=['select WindCode,(3-2*side)*Qty as qty,Type FROM [JasperDB].[dbo].[JasperPositionNew] where account=''' accId ''' and Trade_dt=''' ydate ''';'];
tpos=Utilities.getsqlrtn(conn,sql);
posflag=false;
if ~isempty(tpos)
    tpos=cell2table(tpos,'VariableNames',{'windcode','qty','type'});    
    posflag=true;
end
%1.1 ȡTrading
conn=jtr.db88conn;
sql=['select WindCode,sum((3-2*side)*Qty) as qty,type FROM [JasperDB].[dbo].[JasperTradeDetail] where account=''' accId ''' and Trade_dt=''' date ''' group by windcode,type having sum((3-2*side)*Qty)!=0;'];
torder=Utilities.getsqlrtn(conn,sql);
tradeflag=false;
if ~isempty(torder)    
    torder=cell2table(torder,'VariableNames',{'windcode','trade_qty','type'});
    tradeflag=true;
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
if isempty(tpos)
    return
end
tpos.trade_dt=repmat({date},size(tpos,1),1);
tpos.account=repmat({accId},size(tpos,1),1);
tpos.side=repmat({1},size(tpos,1),1);
tpos.side(tpos.qty<0)={2};
tpos.qty(tpos.qty<0)=-tpos.qty(tpos.qty<0); 
codes=unique(tpos.windcode);
names=w.wss(codes,'sec_name');
tpos.name=cellfun(@(x) names(strcmp(x,codes)==1),tpos.windcode);
tpos.marketvalue=repmat({0},size(tpos,1),1);
tpos.adjustfactor=repmat({1},size(tpos,1),1);
tpos.typedetail=tpos.type;
indexlist={'000300.SH','000016.SZ','000905.SH','000852.SH'};
tpos.typedetail(cellfun(@(x) contains(x,indexlist),tpos.windcode))={'INDEX'};
tpos.dzqty=repmat({0},size(tpos,1),1);

conn=jtr.db88conn;
res=Utilities.upsert(conn,'JasperDB.dbo.JasperPosition',tpos.Properties.VariableNames,[1 0 0 1 1 1 0 0 0 1 0],table2cell(tpos));
fprintf('upsert JasperPosition(from yestPos&jasperTrade):insert %d,update %d \n',sum(res==1),sum(res==0)); 
w.close;
end