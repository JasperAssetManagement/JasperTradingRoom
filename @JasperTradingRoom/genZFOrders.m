function genZFOrders(date,type,varargin)
% ÿ������ZFģ�͵Ľ��׵�����������������ʱ����������Ӧ�������
%   ��Ҫ��ȡ��
%       1.��Ҫ���ɵ��˻�
%       2.ÿ���˻��ĳֲ���ֵ
%       3.ÿ���˻���ʹ��ģ��
%       4.ÿ���˻��ĳɽ�����ʽ
% input:     
% date:      ���ڣ�֧��yyyymmdd���ͺ���������
% type:      �˻����ͣ�0-ȫ�˻�������varargin����;1-ֻ����varargin���˻�
% varargin:  {'01' -200;'13' 20} ��ÿ���˻��ĳֲ���ֵ�ļӼ�����Ԫ��
%            ���û��varargin��������в�Ʒ�����ɳɽ���������У���ֻ��������Ĳ�Ʒ
% ��: JasperTradingRoom.genZFOrders(today(),1,{'06' -40;'23' 0})
% ��: JasperTradingRoom.genZFOrders(today(),0,{'06' -40;'23' 0})
% by Neo - 2017.11.29 
jtr = JasperTradingRoom;
stAccList = jtr.getaccounts;
if ( nargin == 0 ) 
    date=datestr(today(),'yyyymmdd');
    %cAccouts=stAccList.ids;
    cAccounts=jtr.getzfaccounts(date);
    dchgAmts=zeros(size(cAccounts,1),1);
elseif ( nargin == 1)
    if isnumeric(date)
        date=datestr(date,'yyyymmdd');     
    end
else
    if isnumeric(date)
        date=datestr(date,'yyyymmdd'); 
    end
    if type == 0 %����ȫ���˻����׵�       
        tAccounts=cell2table(jtr.getzfaccounts(date),'VariableNames',{'account'});
        tchgAcc=cell2table(varargin{:},'VariableNames',{'account','amount'});        
        tAccounts=outerjoin(tAccounts,tchgAcc,'MergeKeys',1);
        tAccounts.amount(isnan(tAccounts.amount))=0;
        cAccounts=tAccounts.account;
        dchgAmts=tAccounts.amount;       
    elseif type == 1      
        cAccounts=varargin{1}(:,1);
        dchgAmts=cell2mat(varargin{1}(:,2));
    end    
end
ydate=Utilities.tradingdate(datenum(date,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
w=windmatlab;
%% ��ÿ���˻����д������ɽ�����Ҫ���׵ĵ���
conn=jtr.db88conn;
tpacc=cellfun(@(x) ['''' x ''','],cAccounts,'un',0);
tpacc=char(cat(2,tpacc{:}));
sql=['select account,windcode,SUM(qty) as qty from (select account,windcode,qty-dzqty as qty from [JasperDB].[dbo].[JasperPositionNew]' ...
     ' where [Type]=''S'' and Trade_dt=''' ydate ''' and Account in (' tpacc(1:end-1) ') union all ' ...
     'select account,windcode,-qty from [JasperDB].[dbo].[JasperOtherPosition] where [Type]=''S'' and Trade_dt=''' ydate ''' and Account in (' tpacc(1:end-1) ')) a' ...
     ' group by Account,WindCode having SUM(qty)>0 order by Account,WindCode;'];
rowdata=Utilities.getsqlrtn(conn,sql);
if isempty(rowdata)
    tbpos=cell2table({tpacc(2:end-2),'000001.SZ',0},'VariableNames',{'account','windcode','qty'});
else
    tbpos=cell2table(rowdata,'VariableNames',{'account','windcode','qty'});
end
conn=jtr.db88conn;
sql=['SELECT [Account],[Symbol],[Weight] FROM [JasperDB].[dbo].[JasperZFOrders] ' ...
    'where Account in (' tpacc(1:end-1) ') and [Date] = ''' date ''' order by Account,Symbol;'];
rowdata=Utilities.getsqlrtn(conn,sql);
tbtar=cell2table(rowdata,'VariableNames',{'account','windcode','weight'});

code=union(tbpos.windcode,tbtar.windcode);
closeprice=w.wsd(code,'close',ydate,ydate);
name=w.wss(code,'sec_name');
tbpos.closeprice=arrayfun(@(x) closeprice(strcmp(x,code)==1),tbpos.windcode);
tbpos.closeprice(isnan(tbpos.closeprice))=0;
tbpos.amount=tbpos.closeprice.*tbpos.qty;
tbpos.name=cellfun(@(x) name(strcmp(x,code)==1),tbpos.windcode);
tbpos.name(cellfun(@(x) any(isnan(x)),tbpos.name))={''};
tbtar.closeprice=arrayfun(@(x) closeprice(strcmp(x,code)==1),tbtar.windcode);
tbtar.name=cellfun(@(x) name(strcmp(x,code)==1),tbtar.windcode);

for i=1:length(cAccounts)
    posrows=strcmp(tbpos.account,cAccounts(i))==1;
    tarrows=strcmp(tbtar.account,cAccounts(i))==1;
    accrow=strcmp(stAccList.ids,cAccounts(i))==1;    
    tpos=tbpos(posrows,{'windcode','name','qty','closeprice'});   
    ttar=tbtar(tarrows,{'windcode','name','weight','closeprice'}); 
    stAccinfo.posAmt=sum(tbpos.amount(posrows));%+dchgAmts(i)*10000;
    stAccinfo.id=cAccounts{i};
    stAccinfo.asset=stAccList.assets(accrow);
    stAccinfo.trader=stAccList.traders{accrow};
    stAccinfo.system=stAccList.systems{accrow};
    stAccinfo.date=date;
    stAccinfo.model=stAccList.models{accrow};
    
    %ȥ��ͣ�ƹ�Ʊ���ǵ�ͣ�Ĺ�Ʊ
    code=union(tpos.windcode,ttar.windcode);
    cStatToday=w.wss(code,'trade_status',['tradeDate=' date]);
    status=arrayfun(@(x) cStatToday(strcmp(x,code)==1),tpos.windcode);
    tpos(~strcmp(status,'����')==1,:)=[];
    status=arrayfun(@(x) cStatToday(strcmp(x,code)==1),ttar.windcode);
    ttar(~strcmp(status,'����')==1,:)=[];
    
    pctchg=w.wsq(tpos.windcode,'rt_pct_chg');
    tpos(abs(pctchg)>0.098,:)=[];
    pctchg=w.wsq(ttar.windcode,'rt_pct_chg');
    ttar(abs(pctchg)>0.098,:)=[];        
    
    genOrders(tpos,ttar,dchgAmts(i)*10000,dchgAmts(i)*10000,inf,stAccinfo,w); 
   
end
end

%% ���ɽ�����ϸ������Ӧ���
function genOrders(tpos,ttar,dchgAmt,tgtdiff,prediff,stAccinfo,w)
%tpos:�ֲ� ttar:Ŀ����� dchgAmt:ÿ�γ��Եı䶯���
%tgtdiff:Ŀ��䶯���, prediff:�ϴβ����� stAccInfo:�˻���Ϣ
%���㽻�׵�����
    tpd=stAccinfo.posAmt+dchgAmt;
    ttar.targetqty=ttar.weight*tpd./ttar.closeprice;
    torder=outerjoin(tpos,ttar,'MergeKeys',1);
    torder.qty(isnan(torder.qty))=0;
    torder.targetqty(isnan(torder.targetqty))=0;
    torder.tradeqty=round(torder.targetqty-torder.qty,-2);
    torder(torder.tradeqty==0,:)=[];
    torder.tradeamount=torder.tradeqty.*torder.closeprice;
%     torder(abs(torder.tradeamount)<10000,:)=[]; %��Ϊ���׷���ԭ��,С��10000�Ĳ�����
%     torder(abs(torder.tradeamount)<stAccinfo.posAmt*0.0002,:)=[];%С�ڳֲ�2bps��Ҳ������    
    torder.stockcode=cellfun(@(x) x(1:6),torder.windcode,'un',0);
    if stAccinfo.posAmt==0 
        benchmarkAmt=stAccinfo.asset;
    else
        benchmarkAmt=stAccinfo.posAmt;
    end
    
%���������������������return��flag=1,��������������return��warning
if abs(tgtdiff-sum(torder.tradeamount))<=benchmarkAmt*0.005 || abs(tgtdiff-sum(torder.tradeamount))==abs(prediff)   
    fprintf('�˻� %s, ����%8.2f��Ԫ������%8.2f��Ԫ������%8.2f��Ԫ����������%8.2f��Ԫ��\n',stAccinfo.id,sum(torder.tradeamount(torder.tradeqty>0))/10000, ...
        abs(sum(torder.tradeamount(torder.tradeqty<0))/10000),sum(torder.tradeamount)/10000,dchgAmt/10000);    
    JasperTradingRoom.makeorderfile(torder,stAccinfo.id,stAccinfo.trader,stAccinfo.system);  
    %realinsparam=sum(torder.tradeamount);
    
     %ͬʱ���µ�ָ��/ָ����ϸ����
    tins=cell2table({stAccinfo.date,stAccinfo.id,stAccinfo.model,tgtdiff/10000,'DJ',stAccinfo.trader,dchgAmt/10000}, ...
        'VariableNames',{'trade_dt','account','modelname','insparam','advisor','remark','realinsparam'});
    torder=torder(:,{'windcode','tradeqty'});
    torder.qty=torder.tradeqty;
    torder.tradeqty=[];
    torder.trade_dt=repmat(stAccinfo.date,size(torder,1),1);
    JasperTradingRoom.insertInstruction2DB(tins,torder);
    return;
elseif abs(tgtdiff-sum(torder.tradeamount))>abs(prediff)    
    warning('genZFOrders:LogicError','the diff is not convergent.');
    return;
else  
    genOrders(tpos,ttar,dchgAmt+(tgtdiff-sum(torder.tradeamount)),tgtdiff,tgtdiff-sum(torder.tradeamount),stAccinfo,w);  
end
end
