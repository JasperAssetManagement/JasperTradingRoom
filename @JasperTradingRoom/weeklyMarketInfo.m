function weeklyMarketInfo()
dateStyle='yyyymmdd';
% cal the day of the week
date2day=@(s)mod(datenum(s,dateStyle)-datenum('00000101',dateStyle)-1,7);
s_date=datestr(today(),'yyyymmdd');

i_startDate=datenum(s_date,dateStyle)-mod(date2day(s_date)-1,7);
s_startDate=datestr(i_startDate,dateStyle);
i_endDate=datenum(s_date,dateStyle)+(7-mod(date2day(s_date)-1,7)-1);
s_endDate=datestr(i_endDate,dateStyle);

w=windmatlab;
fprintf('*************�г�������Ϣ************* \n');
%log=sprintf('%s \n%s',log,JStrading.weeklyinfo);
weeklyinfo;
fprintf('*************�г��ʽ���************* \n');
StatAShareMarketInfo( s_startDate,s_endDate,w)
fprintf('*************���������Ϣ************* \n');
StatIssueCommAuditInfo( s_startDate,s_endDate )

w.close;
end

function weeklyinfo()
% weeklyinfo �г�����ָ���ܱ���
% - by Lary 2017.05.20

%% ����
% ���ܹ��С���ָ�ڻ�����Ʒ�ڻ��ɽ���
% ��ҵ�ǵ�һ��
% �����ǵ�һ��
% ��ֵ�ǵ�һ��
% ��Ʒ�ǵ�һ��
% ��ծ���������ߡ���������
nRpts = 5; % ��ҵ�ǵ���ǰn��
nGs = 10; % ��ֵ��λ������

%% ����Ԥ����
if ~exist('RQuotation','var')
load('\\192.168.1.180\mdb\RQuotation.mat')
end
if ~exist('CapitalQuotation','var')
load('\\192.168.1.180\mdb\CapitalQuotation.mat')
end
% load('\\192.168.1.180\mdb\IpoTradable.mat')
load('\\192.168.1.180\mdb\TradeStatus.mat')

w = windmatlab;
% if hour(now)>15 || (hour(now)==15 && minute(now())>15)
%     dToday = Utilities.tradingdate;
% else
%     dToday = Utilities.tradingdate(today(),-1);
% end
dToday = Utilities.tradingdate;
if weekday(dToday) < weekday(Utilities.tradingdate(dToday,1))
    % dToday���Ǳ������һ��������ʱ�������������һ��������
    tpdates = Utilities.tradingdate(1,1,'start',dToday-30,'end',dToday);
    ixEOW = find(diff(weekday(tpdates))<0);
    dToday = tpdates(ixEOW(end));
end

tpdates = Utilities.tradingdate(1,1,'start',dToday-30,'end',dToday);

ixEOW = find(diff(weekday(tpdates))<0);
ixEOW1 = ixEOW(end-1);
ixEOW2 = ixEOW(end);
ndaysthisweek = numel(tpdates)-ixEOW2;
ndayslastweek = ixEOW2 - ixEOW1;

dYst = tpdates(ixEOW2);

%% A��ָ������ҵ���������
cCodes = {'000016.SH','000300.SH','000905.SH','000852.SH'};
cNames = {'��֤50','����300','��֤500','��֤1000'};
chAmt = w.wss('881001.WI','amt',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W')/100000000;
chYstAmt = w.wss('881001.WI','amt',['tradeDate=' datestr(dYst,'yyyymmdd')],'cycle=W')/100000000;
chAmtRep = ['�������гɽ���ϼ�' num2str(chAmt,'%10.2f') '��Ԫ��'];
chAmtRep = strcat(chAmtRep,['�վ��ɽ���' num2str(chAmt/ndaysthisweek,'%10.2f') '��Ԫ����ǰֵ' num2str(chYstAmt/ndayslastweek,'%10.2f') '��Ԫ']);
if chAmt>chYstAmt
    chAmtRep = strcat(chAmtRep,['����' num2str(chAmt/ndaysthisweek - chYstAmt/ndayslastweek,'%10.2f')  '��Ԫ��\n']);
else
    chAmtRep = strcat(chAmtRep,['����' num2str(-chAmt/ndaysthisweek + chYstAmt/ndayslastweek,'%10.2f')  '��Ԫ��\n']);
end

fprintf(chAmtRep)

dData = w.wss(cCodes,'close,pct_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
nCodes = numel(cCodes);

chStyleRep = [];
for iCode = 1:nCodes
    tpClose = dData(iCode,1);
    tpPctChg = dData(iCode,2);
    if tpPctChg>0
        tpch = [cNames{iCode} '����' num2str(tpPctChg,'%5.2f') '%%'];
    elseif dData(iCode,2)<0
        tpch = [cNames{iCode} '�µ�' num2str(abs(tpPctChg),'%5.2f') '%%'];
    else
        tpch = [cNames{iCode} '��ƽ'];
    end
    tpch = strcat(tpch,'������',num2str(tpClose,'%10.2f'),'�㡣\n');
    chStyleRep = strcat(chStyleRep,tpch);
end
fprintf(chStyleRep)

%% �����ָ�ڻ��ɽ������ֲ������
cFFCodes = {'IF00.CFE','IF01.CFE','IF02.CFE','IF03.CFE','IC00.CFE','IC01.CFE','IC02.CFE','IC03.CFE','IH00.CFE','IH01.CFE','IH02.CFE','IH03.CFE'}';
dData = w.wss(cFFCodes,'volume,amt,oi,oi_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
tpsum = sum(dData);
chFinFuRep = ['��ָ�ڻ��ϼƳɽ�' num2str(tpsum(1)/10000,'%10.2f') '���֣��ɽ���' num2str(tpsum(2)/100000000,'%10.2f') '��Ԫ���ϼƳֲ�' ...
    num2str(tpsum(3)/10000,'%10.2f') '���֣�'];
if tpsum(4)>0
    chFinFuRep = strcat(chFinFuRep,['����������' num2str(tpsum(4)) '�֡�\n']);
elseif tpsum(4)<0
    chFinFuRep = strcat(chFinFuRep,['�����ܼ���' num2str(-tpsum(4)) '�֡�\n']);
else
    chFinFuRep = strcat(chFinFuRep,['�����ܳ�ƽ��\n']);
end

fprintf(chFinFuRep)

%% ��ҵ����������������������

% ��ҵ
cCSI_Inds = {'CI005001.WI';'CI005002.WI';'CI005003.WI';'CI005004.WI';
    'CI005005.WI';'CI005006.WI';'CI005007.WI';'CI005008.WI';
    'CI005009.WI';'CI005010.WI';'CI005011.WI';'CI005012.WI';
    'CI005013.WI';'CI005014.WI';'CI005015.WI';'CI005016.WI';
    'CI005017.WI';'CI005018.WI';'CI005019.WI';'CI005020.WI';
    'CI005021.WI';'CI005022.WI';'CI005023.WI';'CI005024.WI';
    'CI005025.WI';'CI005026.WI';'CI005027.WI';'CI005028.WI';'CI005029.WI'};

cIndNames = w.wss(cCSI_Inds,'sec_name');
cIndNames = cellfun(@(x)x(1:end-4),cIndNames,'UniformOutput',false);
dData = w.wss(cCSI_Inds,'pct_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
[sdPctChg,ixsdPctChg] = sort(dData(:,1),'descend');

cRtns = cellstr(num2str(sdPctChg,'%5.2f'));
cRep1 = [cIndNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';
cRep2 = [cIndNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';

chIndRep1 = [cRep1{:}];
chIndRep2 = [cRep2{:}];

chIndRep1 = ['������ҵΪ��' chIndRep1(1:end-1) '��\n'];
chIndRep2 = ['�����ҵΪ��' chIndRep2(1:end-1) '��\n'];

fprintf(chIndRep1)
fprintf(chIndRep2)

% ����
cTopicList = cellstr(num2str((884001:884999)'));
cTopicList = cellfun(@(x)([x '.WI']),cTopicList,'UniformOutput',false);
cTopicNames = w.wss(cTopicList,'sec_name',['tradeDate=' datestr(dToday,'yyyymmdd')]);
bGoodTopic = cellfun('length',cTopicNames)>1;
cTopicList = cTopicList(bGoodTopic);
cTopicNames = cTopicNames(bGoodTopic);
dData = w.wss(cTopicList,'pct_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');

bGoodTopic2 = ~isnan(dData);
%cTopicList = cTopicList(bGoodTopic2);
cTopicNames = cTopicNames(bGoodTopic2);
dData = dData(bGoodTopic2);

[sdPctChg,ixsdPctChg] = sort(dData(:,1),'descend');
cRtns = cellstr(num2str(sdPctChg,'%5.2f'));
cRep1 = [cTopicNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';
cRep2 = [cTopicNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';
chTopicRep1 = [cRep1{:}];
chTopicRep2 = [cRep2{:}];
chTopicRep1 = ['���Ǹ���Ϊ��' chTopicRep1(1:end-1) '��\n'];
chTopicRep2 = ['�������Ϊ��' chTopicRep2(1:end-1) '��\n'];
fprintf(chTopicRep1)
fprintf(chTopicRep2)

%% ��Ʒ�ڻ���Ʒ���ǵ����ɽ������ֲ������
% �����Ʒָ���ǵ�����
cComIndex = {'AFI.WI';'AGFI.WI';'ALFI.WI';'AUFI.WI';
    'BUFI.WI';'CFFI.WI';'CFI.WI';'CSFI.WI';'CUFI.WI';
    'FGFI.WI';'HCFI.WI';'IFI.WI';'JDFI.WI';
    'JFI.WI';'JMFI.WI';'LFI.WI';'MAFI.WI';'MFI.WI';
    'NIFI.WI';'OIFI.WI';'PBFI.WI';'PFI.WI';'PPFI.WI';
    'RBFI.WI';'RMFI.WI';'RUFI.WI';'SMFI.WI';'SNFI.WI';
    'SRFI.WI';'TAFI.WI';'ZCFI.WI';'VFI.WI';'YFI.WI';'ZNFI.WI'};

cComNames = w.wss(cComIndex,'sec_name');
cComNames = cellfun(@(x)x(1:end-2),cComNames,'UniformOutput',false);
dData = w.wss(cComIndex,'pct_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
[sdPctChg,ixsdPctChg] = sort(dData(:,1),'descend');

cRtns = cellstr(num2str(sdPctChg,'%5.2f'));
cRep1 = [cComNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';
cRep2 = [cComNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'��'},nRpts,1)]';

chComRep1 = [cRep1{:}];
chComRep2 = [cRep2{:}];

chComRep1 = ['������ƷΪ��' chComRep1(1:end-1) '��\n'];
chComRep2 = ['�����ƷΪ��' chComRep2(1:end-1) '��\n'];

fprintf(chComRep1)
fprintf(chComRep2)

% �ɽ��������

% �ֲ���ֵ����

%% �̶������г��������ծ�ڻ���������ȯ����ع����ۡ���ծ�������ʡ�Libor�����й���������
cIntRts = {'SHIBORON.IR,SHIBOR1M.IR,SHIBOR3M.IR,CGB5Y.WI,CGB10Y.WI'};
cIntNames = w.wss(cIntRts,'sec_name');
cIntNames = cellfun(@(x)strrep(x,'(CGBB)',''),cIntNames,'UniformOutput',false);
dClose = w.wss(cIntRts,'close',['tradeDate=' datestr(dToday,'yyyymmdd')],'priceAdj=U','cycle=D');
dLastClose = w.wss(cIntRts,'close',['tradeDate=' datestr(dYst,'yyyymmdd')],'priceAdj=U','cycle=D');
dChg = dClose - dLastClose;

bGood = ~isnan(dClose);
dClose = dClose(bGood);
%dLastClose = dLastClose(bGood);
dChg = dChg(bGood);
cIntNames = cIntNames(bGood);
nInts = numel(cIntNames);

chIntRpt = [];
for iInt = 1:nInts
    tpch = [cIntNames{iInt} '��' num2str(dClose(iInt)*100) 'bps��������'];
    if dChg(iInt)>0
        tpch = strcat(tpch,['��' num2str(dChg(iInt)*100) 'bps��\n']);
    elseif dChg(iInt)<0
        tpch = strcat(tpch,['��' num2str(-dChg(iInt)*100) 'bps��\n']);
    else
        tpch = strcat(tpch,'��ƽ��\n');
    end
    chIntRpt = strcat(chIntRpt,tpch);
end
fprintf(chIntRpt)

%% ��ֵ��λ����һ��
% if ~isequal(CapitalQuotation.date,RQuotation.date) || ~isequal(TradeStatus.dates,RQuotation.date) || ~isequal(CapitalQuotation.stockcode,RQuotation.stockcode)
%     error('bad data.')
% end
ixYst = find(RQuotation.date == dYst);
ixToday = find(RQuotation.date == dToday);
[isin, rows]=ismember(RQuotation.stockcode,TradeStatus.header);
codes=TradeStatus.header(rows(isin==1));
pctchanges=RQuotation.pctchange(ixYst:ixToday,isin==1);
hissharevalues=CapitalQuotation.totalsharevalue(ixYst-250,rows(isin==1));
tStat = table(codes,TradeStatus.data(ixYst,rows(isin==1))');
tpt = table(codes);

[isin, rows]=ismember(codes,CapitalQuotation.stockcode);
tpCaps = CapitalQuotation.totalsharevalue(ixYst,rows(isin==1));
tTrateStatus = join(tpt,tStat);

bGood = ~isnan(hissharevalues) & tTrateStatus.Var2'>3;

% for i = 1:10
% a1 = max(tpCaps(logical(dCapGroupWeights1(i,:))));
% a2 = min(tpCaps(logical(dCapGroupWeights1(i,:))));
% [a2,a1]./100000
% end

tpCaps(~bGood) = nan;
[~,tpix] = sort(tpCaps);
tpixx = tpix;
tpixx(tpix) = 1:numel(tpix);
tpq = tpixx/sum(bGood);

dCapGroupWeights1 = [];
dCapGroupWeights2 = [];
for iG = 1:nGs
    tpb = tpq>(iG-1)/nGs & tpq<=iG/nGs;
    tpcappp = tpCaps;
    tpcappp(~tpb) = 0;
    tpw = tpcappp./sum(tpcappp);
    dCapGroupWeights1 = cat(1,dCapGroupWeights1,tpb/sum(tpb));
    dCapGroupWeights2 = cat(1,dCapGroupWeights2,tpw);
end
dCGW1 = dCapGroupWeights1';
dCGW2 = dCapGroupWeights2';

tprtns = pctchanges/100;
dWR = exp(sum(log(1+tprtns)))-1;
tpbGood = ~isnan(dWR);

dCWR1 = dWR(tpbGood)*dCGW1(tpbGood,:);
dCWR2 = dWR(tpbGood)*dCGW2(tpbGood,:);

fh = figure(2);
bar([dCWR1;dCWR2]')
fh.Children.XTick = [0:11];
fh.Children.XTickLabels{1} = 'С��ֵ';
fh.Children.XTickLabels{end} = '����ֵ';
fh.Children.XLim = [0 11];
title('����A����ֵ����һ��')
legend({'��ƽ��','��ֵ��Ȩ'})

%tpMnCap = tpCaps(bGood)*dCGW1(bGood,:);

%% Output
%chOutput = [chStyleRep,'\n',chFinFuRep,'\n',chTopicRep1,'\n',chTopicRep2,'\n',chComRep1,'\n',chComRep2,'\n',chIntRpt,'\n'];

end

% stat weekly data of issueCommAudit
function [] = StatIssueCommAuditInfo( s_startDate,s_endDate )
jtr=JasperTradingRoom;
resMap=containers.Map;
resMap('1')={'�����'};    
resMap('2')={'ȡ�����'}; 
resMap('3')={'ͨ��'};
resMap('4')={'δͨ��'};
resMap('5')={'�ݻ����'};

sqlstr=strcat('SELECT S_IC_DATE,COUNT(1),rtrim(S_IC_AUDITTYPE),rtrim(S_IC_AUDITOCETYPE) FROM [WINDFILESYNC].[dbo].[ASHAREISSUECOMMAUDIT]',32,...
    'where s_ic_date between ''',s_startDate,''' and ''',s_endDate,''' group by S_IC_DATE,S_IC_AUDITTYPE,S_IC_AUDITOCETYPE;');
conn=jtr.db85conn;
data=Utilities.getsqlrtn(conn,sqlstr);
if (~isempty(data))    
    qtys=cell2mat(data(:,2));
    audittypes=data(:,3);
    auditocetypes=cell2mat(data(:,4));
end
[sums,grps]=grpstats(qtys,{audittypes,auditocetypes},{'sum','gname'});
[sortedResTypes,ind]=sort(grps(:,2));
sortedTypes=grps(ind,1);
sortedSums=sums(ind);
for i=1:length(sums)    
    if strcmp(sortedResTypes{i},'1')==1
        fprintf('����ί�������� ���ͣ�%-4s �����%-4s ������%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    elseif strcmp(sortedResTypes{i},'3')==1
        fprintf('����ί�������� ���ͣ�%-4s �����%-4s ������%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    else
        fprintf('����ίδ����� ���ͣ�%-4s �����%-4s ������%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    end
end
end

function [] = StatAShareMarketInfo( s_startDate,s_endDate,w )
%���������ϯλͳ��
jtr=JasperTradingRoom;
sqlstr=strcat('SELECT sum([S_STRANGE_BUYAMOUNT])/100000000,sum([S_STRANGE_SELLAMOUNT])/100000000,(sum([S_STRANGE_BUYAMOUNT])-sum([S_STRANGE_SELLAMOUNT]))/100000000 as net',32,...
    'FROM [WINDFILESYNC].[dbo].[ASHARESTRANGETRADE] where S_STRANGE_ENDDATE between ''',s_startDate,''' and ''',s_endDate,''' and S_STRANGE_TRADERNAME=''����ר��'';');
conn=jtr.db85conn;
data=Utilities.getsqlrtn(conn,sqlstr);
if (~isempty(data))    
    buyA=cell2mat(data(:,1));
    sellA=cell2mat(data(:,2));
    netA=cell2mat(data(:,3));
end
if netA>=0 
    netSide='������';
else
    netSide='������';
end
fprintf('�����������У�����ϯλ %s��%4.2f�ڣ��������룺%4.2f�ڣ�������%4.2f�� \n',netSide,netA,buyA,sellA);

%���ܽ����ֵ�Ƚ�
[w_data]=w.tdaysoffset(-1,s_startDate);
s_preTradeDt=datestr(w_data,'yyyymmdd');

sqlstr=strcat('SELECT sum(a.s_share_lst*b.s_dq_close) FROM [WINDFILESYNC].[dbo].[ASHAREFREEFLOATCALENDAR] a, [WINDFILESYNC].[dbo].[ASHAREEODPRICES] b',32,...
    'where S_INFO_LISTDATE between ''',s_startDate,''' and ''',s_endDate,''' and a.S_INFO_WINDCODE=b.S_INFO_WINDCODE and b.TRADE_DT=''',s_preTradeDt,''';');
conn=jtr.db85conn;
data=Utilities.getsqlrtn(conn,sqlstr);
if (~isempty(data))    
    freeMV=roundn(cell2mat(data)/10000,-2);   
end

s_nextStart=datestr(datenum(s_startDate,'yyyymmdd')+7,'yyyymmdd');
s_nextEnd=datestr(datenum(s_endDate,'yyyymmdd')+7,'yyyymmdd');
[w_data]=w.tdaysoffset(-1,s_nextStart);
s_preTradeDt=datestr(w_data,'yyyymmdd');

sqlstr=strcat('SELECT sum(a.s_share_lst*b.s_dq_close) FROM [WINDFILESYNC].[dbo].[ASHAREFREEFLOATCALENDAR] a, [WINDFILESYNC].[dbo].[ASHAREEODPRICES] b',32,...
    'where S_INFO_LISTDATE between ''',s_nextStart,''' and ''',s_nextEnd,''' and a.S_INFO_WINDCODE=b.S_INFO_WINDCODE and b.TRADE_DT=''',s_preTradeDt,''';');
conn=jtr.db85conn;
data=Utilities.getsqlrtn(conn,sqlstr);
if (~isempty(data))    
    freeNextMV=roundn(cell2mat(data)/10000,-2);
end
netA = freeNextMV-freeMV;
if netA>=0 
    netSide='����';
else
    netSide='����';
end
fprintf('���ܽ������ֵ��%4.2f�ڣ��ϱ���%s��%4.2f�� \n',freeNextMV,netSide,abs(netA));

%���ͨ�ɽ����ͳ��
[w_data]=w.wset('shhktransactionstatistics',strcat('startdate=',s_startDate,';enddate=',s_endDate,';cycle=week;currency=hkd'));
buySH=cell2mat(w_data(3));
sellSH=cell2mat(w_data(4));
SHnet=buySH-sellSH;
SHbuyHK=cell2mat(w_data(8));
SHsellHK=cell2mat(w_data(9));
HKnet1=SHbuyHK-SHsellHK;

rowData = Utilities.excelimport('D:\�ɽ�ͳ��.xlsx',1,2,3,'columns',[3 4 5 8 9 10]);
buySZ=rowData(2,1);
sellSZ=rowData(2,2);
SZnet=rowData(2,3);
SZbuyHK=rowData(2,4);
SZsellHK=rowData(2,5);
HKnet2=rowData(2,6);

fprintf('���ܻ���ͨ|���ͨ �����ʽ�%4.2f�ڣ����л���ͨ����%4.2f�ڣ�����%4.2f�ڣ����ͨ����%4.2f�ڣ�����%4.2f�ڣ�\n�����ʽ�%4.2f�ڣ��۱ң�,����%4.2f�ڣ�����%4.2f�ڡ� \n',...
    SHnet+SZnet,buySH,sellSH,buySZ,sellSZ,HKnet1+HKnet2,SHbuyHK+SZbuyHK,SHsellHK+SZsellHK);

end