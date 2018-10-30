function chOutput = weeklyinfo()
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
if hour(now)>15 || (hour(now)==15 && minute(now())>15)
    dToday = Utilities_zjx.tradingdate;
else
    dToday = Utilities_zjx.tradingdate(today(),-1);
end

if weekday(dToday) < weekday(Utilities_zjx.tradingdate(dToday,1))
    % dToday���Ǳ������һ��������ʱ�������������һ��������
    tpdates = Utilities_zjx.tradingdate(1,1,'start',dToday-30,'end',dToday);
    ixEOW = find(diff(weekday(tpdates))<0);
    dToday = tpdates(ixEOW(end));
end

tpdates = Utilities_zjx.tradingdate(1,1,'start',dToday-30,'end',dToday);

ixEOW = find(diff(weekday(tpdates))<0);
ixEOW1 = ixEOW(end-1);
ixEOW2 = ixEOW(end);
ndaysthisweek = numel(tpdates)-ixEOW2;
ndayslastweek = ixEOW2 - ixEOW1;

dYst = tpdates(ixEOW2);

chDiaryFile = ['F:\DailyRpt\����������' datestr(dToday,'yyyy-mm-dd') '.txt'];
if exist(chDiaryFile,'file')
    delete(chDiaryFile)
end
% diary(chDiaryFile)

%% A��ָ������ҵ���������
chA = '881001.WI';
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
cTopicList = cTopicList(bGoodTopic2);
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
dLastClose = dLastClose(bGood);
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
if ~isequal(CapitalQuotation.date,RQuotation.date) || ~isequal(TradeStatus.dates,RQuotation.date) || ~isequal(CapitalQuotation.stockcode,RQuotation.stockcode)
    error('bad data.')
end
ixYst = find(RQuotation.date == dYst);
ixToday = find(RQuotation.date == dToday);
tpCaps = CapitalQuotation.totalsharevalue(ixYst,:);
tStat = table(TradeStatus.header,TradeStatus.data(ixYst,:)');
tpt = table(RQuotation.stockcode);
tTrateStatus = join(tpt,tStat);

bGood = ~isnan(CapitalQuotation.totalsharevalue(ixYst-250,:)) & tTrateStatus.Var2'>3;

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

tprtns = RQuotation.pctchange(ixYst:ixToday,:)/100;
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

tpMnCap = tpCaps(bGood)*dCGW1(bGood,:);

% diary off

%% Output
chOutput = [chStyleRep,'\n',chFinFuRep,'\n',chTopicRep1,'\n',chTopicRep2,'\n',chComRep1,'\n',chComRep2,'\n',chIntRpt,'\n'];

end




