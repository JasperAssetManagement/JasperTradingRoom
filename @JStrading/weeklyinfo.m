function chOutput = weeklyinfo()
% weeklyinfo 市场情绪指标周报。
% - by Lary 2017.05.20

%% 参数
% 上周股市、股指期货、商品期货成交量
% 行业涨跌一览
% 概念涨跌一览
% 市值涨跌一览
% 商品涨跌一览
% 国债收益率曲线、信用利差
nRpts = 5; % 行业涨跌幅前n名
nGs = 10; % 市值档位数量。

%% 数据预处理
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
    % dToday不是本周最后一个交易日时，查找上周最后一个交易日
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

chDiaryFile = ['F:\DailyRpt\周行情综述' datestr(dToday,'yyyy-mm-dd') '.txt'];
if exist(chDiaryFile,'file')
    delete(chDiaryFile)
end
% diary(chDiaryFile)

%% A股指数、行业、概念情况
chA = '881001.WI';
cCodes = {'000016.SH','000300.SH','000905.SH','000852.SH'};
cNames = {'上证50','沪深300','中证500','中证1000'};
chAmt = w.wss('881001.WI','amt',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W')/100000000;
chYstAmt = w.wss('881001.WI','amt',['tradeDate=' datestr(dYst,'yyyymmdd')],'cycle=W')/100000000;
chAmtRep = ['本周两市成交额合计' num2str(chAmt,'%10.2f') '亿元，'];
chAmtRep = strcat(chAmtRep,['日均成交额' num2str(chAmt/ndaysthisweek,'%10.2f') '亿元，较前值' num2str(chYstAmt/ndayslastweek,'%10.2f') '亿元']);
if chAmt>chYstAmt
    chAmtRep = strcat(chAmtRep,['增加' num2str(chAmt/ndaysthisweek - chYstAmt/ndayslastweek,'%10.2f')  '亿元。\n']);
else
    chAmtRep = strcat(chAmtRep,['减少' num2str(-chAmt/ndaysthisweek + chYstAmt/ndayslastweek,'%10.2f')  '亿元。\n']);
end

fprintf(chAmtRep)

dData = w.wss(cCodes,'close,pct_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
nCodes = numel(cCodes);

chStyleRep = [];
for iCode = 1:nCodes
    tpClose = dData(iCode,1);
    tpPctChg = dData(iCode,2);
    if tpPctChg>0
        tpch = [cNames{iCode} '上涨' num2str(tpPctChg,'%5.2f') '%%'];
    elseif dData(iCode,2)<0
        tpch = [cNames{iCode} '下跌' num2str(abs(tpPctChg),'%5.2f') '%%'];
    else
        tpch = [cNames{iCode} '收平'];
    end
    tpch = strcat(tpch,'，收于',num2str(tpClose,'%10.2f'),'点。\n');
    chStyleRep = strcat(chStyleRep,tpch);
end
fprintf(chStyleRep)

%% 三大股指期货成交量、持仓量情况
cFFCodes = {'IF00.CFE','IF01.CFE','IF02.CFE','IF03.CFE','IC00.CFE','IC01.CFE','IC02.CFE','IC03.CFE','IH00.CFE','IH01.CFE','IH02.CFE','IH03.CFE'}';
dData = w.wss(cFFCodes,'volume,amt,oi,oi_chg',['tradeDate=' datestr(dToday,'yyyymmdd')],'cycle=W');
tpsum = sum(dData);
chFinFuRep = ['股指期货合计成交' num2str(tpsum(1)/10000,'%10.2f') '万手，成交额' num2str(tpsum(2)/100000000,'%10.2f') '亿元。合计持仓' ...
    num2str(tpsum(3)/10000,'%10.2f') '万手，'];
if tpsum(4)>0
    chFinFuRep = strcat(chFinFuRep,['较上周增加' num2str(tpsum(4)) '手。\n']);
elseif tpsum(4)<0
    chFinFuRep = strcat(chFinFuRep,['较上周减少' num2str(-tpsum(4)) '手。\n']);
else
    chFinFuRep = strcat(chFinFuRep,['与上周持平。\n']);
end

fprintf(chFinFuRep)

%% 行业领涨领跌、概念板块领涨领跌

% 行业
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
cRep1 = [cIndNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';
cRep2 = [cIndNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';

chIndRep1 = [cRep1{:}];
chIndRep2 = [cRep2{:}];

chIndRep1 = ['领涨行业为：' chIndRep1(1:end-1) '。\n'];
chIndRep2 = ['领跌行业为：' chIndRep2(1:end-1) '。\n'];

fprintf(chIndRep1)
fprintf(chIndRep2)

% 概念
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
cRep1 = [cTopicNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';
cRep2 = [cTopicNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';
chTopicRep1 = [cRep1{:}];
chTopicRep2 = [cRep2{:}];
chTopicRep1 = ['领涨概念为：' chTopicRep1(1:end-1) '。\n'];
chTopicRep2 = ['领跌概念为：' chTopicRep2(1:end-1) '。\n'];
fprintf(chTopicRep1)
fprintf(chTopicRep2)

%% 商品期货各品种涨跌、成交量、持仓量情况
% 万德商品指数涨跌排名
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
cRep1 = [cComNames(ixsdPctChg(1:nRpts)),repmat({'('},nRpts,1),cRtns(1:nRpts),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';
cRep2 = [cComNames(ixsdPctChg(end:-1:end-nRpts+1)),repmat({'('},nRpts,1),cRtns(end:-1:end-nRpts+1),repmat({'%%)'},nRpts,1),repmat({'、'},nRpts,1)]';

chComRep1 = [cRep1{:}];
chComRep2 = [cRep2{:}];

chComRep1 = ['领涨商品为：' chComRep1(1:end-1) '。\n'];
chComRep2 = ['领跌商品为：' chComRep2(1:end-1) '。\n'];

fprintf(chComRep1)
fprintf(chComRep2)

% 成交金额排名


% 持仓市值排名

%% 固定收益市场情况：国债期货、交易所券、逆回购报价、国债隐含利率、Libor、央行公开操作等
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
    tpch = [cIntNames{iInt} '报' num2str(dClose(iInt)*100) 'bps，较上周'];
    if dChg(iInt)>0
        tpch = strcat(tpch,['涨' num2str(dChg(iInt)*100) 'bps。\n']);
    elseif dChg(iInt)<0
        tpch = strcat(tpch,['跌' num2str(-dChg(iInt)*100) 'bps。\n']);
    else
        tpch = strcat(tpch,'持平。\n');
    end
    chIntRpt = strcat(chIntRpt,tpch);
end
fprintf(chIntRpt)

%% 市值档位表现一览
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
fh.Children.XTickLabels{1} = '小市值';
fh.Children.XTickLabels{end} = '大市值';
fh.Children.XLim = [0 11];
title('上周A股市值表现一览')
legend({'简单平均','市值加权'})

tpMnCap = tpCaps(bGood)*dCGW1(bGood,:);

% diary off

%% Output
chOutput = [chStyleRep,'\n',chFinFuRep,'\n',chTopicRep1,'\n',chTopicRep2,'\n',chComRep1,'\n',chComRep2,'\n',chIntRpt,'\n'];

end




