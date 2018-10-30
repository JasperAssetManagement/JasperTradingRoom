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
fprintf('*************市场行情信息************* \n');
%log=sprintf('%s \n%s',log,JStrading.weeklyinfo);
weeklyinfo;
fprintf('*************市场资金动向************* \n');
StatAShareMarketInfo( s_startDate,s_endDate,w)
fprintf('*************行政许可信息************* \n');
StatIssueCommAuditInfo( s_startDate,s_endDate )

w.close;
end

function weeklyinfo()
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
% if hour(now)>15 || (hour(now)==15 && minute(now())>15)
%     dToday = Utilities.tradingdate;
% else
%     dToday = Utilities.tradingdate(today(),-1);
% end
dToday = Utilities.tradingdate;
if weekday(dToday) < weekday(Utilities.tradingdate(dToday,1))
    % dToday不是本周最后一个交易日时，查找上周最后一个交易日
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

%% A股指数、行业、概念情况
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
%cTopicList = cTopicList(bGoodTopic2);
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
%dLastClose = dLastClose(bGood);
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
fh.Children.XTickLabels{1} = '小市值';
fh.Children.XTickLabels{end} = '大市值';
fh.Children.XLim = [0 11];
title('上周A股市值表现一览')
legend({'简单平均','市值加权'})

%tpMnCap = tpCaps(bGood)*dCGW1(bGood,:);

%% Output
%chOutput = [chStyleRep,'\n',chFinFuRep,'\n',chTopicRep1,'\n',chTopicRep2,'\n',chComRep1,'\n',chComRep2,'\n',chIntRpt,'\n'];

end

% stat weekly data of issueCommAudit
function [] = StatIssueCommAuditInfo( s_startDate,s_endDate )
jtr=JasperTradingRoom;
resMap=containers.Map;
resMap('1')={'待表决'};    
resMap('2')={'取消审核'}; 
resMap('3')={'通过'};
resMap('4')={'未通过'};
resMap('5')={'暂缓表决'};

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
        fprintf('发审委新增受理 类型：%-4s 结果：%-4s 数量：%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    elseif strcmp(sortedResTypes{i},'3')==1
        fprintf('发审委新增过会 类型：%-4s 结果：%-4s 数量：%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    else
        fprintf('发审委未予过会 类型：%-4s 结果：%-4s 数量：%d \n',sortedTypes{i},char(resMap(sortedResTypes{i})),sortedSums(i));
    end
end
end

function [] = StatAShareMarketInfo( s_startDate,s_endDate,w )
%龙虎榜机构席位统计
jtr=JasperTradingRoom;
sqlstr=strcat('SELECT sum([S_STRANGE_BUYAMOUNT])/100000000,sum([S_STRANGE_SELLAMOUNT])/100000000,(sum([S_STRANGE_BUYAMOUNT])-sum([S_STRANGE_SELLAMOUNT]))/100000000 as net',32,...
    'FROM [WINDFILESYNC].[dbo].[ASHARESTRANGETRADE] where S_STRANGE_ENDDATE between ''',s_startDate,''' and ''',s_endDate,''' and S_STRANGE_TRADERNAME=''机构专用'';');
conn=jtr.db85conn;
data=Utilities.getsqlrtn(conn,sqlstr);
if (~isempty(data))    
    buyA=cell2mat(data(:,1));
    sellA=cell2mat(data(:,2));
    netA=cell2mat(data(:,3));
end
if netA>=0 
    netSide='净买入';
else
    netSide='净卖出';
end
fprintf('本周龙虎榜中，机构席位 %s：%4.2f亿，其中买入：%4.2f亿，卖出：%4.2f亿 \n',netSide,netA,buyA,sellA);

%本周解禁市值比较
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
    netSide='增加';
else
    netSide='减少';
end
fprintf('下周将解禁市值：%4.2f亿，较本周%s：%4.2f亿 \n',freeNextMV,netSide,abs(netA));

%深沪港通成交金额统计
[w_data]=w.wset('shhktransactionstatistics',strcat('startdate=',s_startDate,';enddate=',s_endDate,';cycle=week;currency=hkd'));
buySH=cell2mat(w_data(3));
sellSH=cell2mat(w_data(4));
SHnet=buySH-sellSH;
SHbuyHK=cell2mat(w_data(8));
SHsellHK=cell2mat(w_data(9));
HKnet1=SHbuyHK-SHsellHK;

rowData = Utilities.excelimport('D:\成交统计.xlsx',1,2,3,'columns',[3 4 5 8 9 10]);
buySZ=rowData(2,1);
sellSZ=rowData(2,2);
SZnet=rowData(2,3);
SZbuyHK=rowData(2,4);
SZsellHK=rowData(2,5);
HKnet2=rowData(2,6);

fprintf('本周沪港通|深港通 北上资金：%4.2f亿，其中沪港通买入%4.2f亿，卖出%4.2f亿；深港通买入%4.2f亿，卖出%4.2f亿；\n南下资金：%4.2f亿（港币）,买入%4.2f亿，卖出%4.2f亿。 \n',...
    SHnet+SZnet,buySH,sellSH,buySZ,sellSZ,HKnet1+HKnet2,SHbuyHK+SZbuyHK,SHsellHK+SZsellHK);

end