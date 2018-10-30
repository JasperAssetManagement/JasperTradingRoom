function [output,tInfo] = holdingstopadj(dToday)
% 停牌股票收益率计算 对每个产品的影响。

%%
jst = JStrading;
zjx = Utilities_zjx;
w = windmatlab;

%% constants
cAMAC_IndInfo = {'H11030.CSI',1;'H11030.CSI',2;'H11030.CSI',3;'H11030.CSI',4;
    'H11030.CSI',5;'H11031.CSI',6;'H11031.CSI',7;'H11031.CSI',8;
    'H11031.CSI',9;'H11031.CSI',10;'H11031.CSI',11;'H11031.CSI',12;
    'H30041.CSI',13;'H30042.CSI',14;'H30043.CSI',15;'H30044.CSI',16;
    'H30044.CSI',17;'H30045.CSI',18;'H30046.CSI',19;'H30047.CSI',20;
    'H30048.CSI',21;'H30049.CSI',22;'H30050.CSI',23;'H30051.CSI',24;
    'H30052.CSI',25;'H30053.CSI',26;'H30054.CSI',27;'H30055.CSI',28;
    'H30056.CSI',29;'H30057.CSI',30;'H30058.CSI',31;'H30059.CSI',32;
    'H30060.CSI',33;'H30061.CSI',34;'H30062.CSI',35;'H30063.CSI',36;
    'H30064.CSI',37;'H30065.CSI',38;'H30066.CSI',39;'H30067.CSI',40;
    'H11050.CSI',41;'H11050.CSI',42;'H11050.CSI',43;'H11041.CSI',44;
    'H11041.CSI',45;'H11041.CSI',46;'H11042.CSI',47;'H11042.CSI',48;
    'H11042.CSI',49;'H11042.CSI',50;'H11045.CSI',51;'H11045.CSI',52;
    'H11043.CSI',53;'H11043.CSI',54;'H11043.CSI',55;'H11043.CSI',56;
    'H11043.CSI',57;'H11043.CSI',58;'H11043.CSI',59;'H11043.CSI',60;
    'H30036.CSI',61;'H30036.CSI',62;'H11044.CSI',63;'H11044.CSI',64;
    'H11044.CSI',65;'H11046.CSI',66;'H11046.CSI',67;'H11046.CSI',68;
    'H11046.CSI',69;'H11047.CSI',70;'H30037.CSI',71;'H30037.CSI',72;
    'H30038.CSI',73;'H30038.CSI',74;'H30038.CSI',75;'H30039.CSI',76;
    'H30039.CSI',77;'H30039.CSI',78;'H30040.CSI',79;'H30040.CSI',80;
    'H30040.CSI',81;'H11049.CSI',82;'H30040.CSI',83;'H30040.CSI',84;
    'H11049.CSI',85;'H11049.CSI',86;'H11049.CSI',87;'H11049.CSI',88;
    'H11049.CSI',89;'H11050.CSI',90};
tAMAC = cell2table(cAMAC_IndInfo,'VariableNames',{'amaccode','seccode'});

%% 停牌股票清单
if exist('dToday','var') && ~isempty(dToday)
%     fprintf('输入的不是交易日，自动调整为最近的一个交易日\n')
    dToday = zjx.tradingdate(dToday);
else
    dToday = zjx.tradingdate(today());
end
wssDateArg = ['tradeDate=' datestr(dToday,'yyyymmdd')];
tInfo = getHoldingList(jst,dToday);
if isempty(tInfo)
    warning(['计算失败：未查到' datestr(dToday,'yyyy年mm月dd日') '的持仓。'])
    output = [];
    return
end
tInfo.windcode = zjx.getwindstockcode(tInfo.code);
cCodes = tInfo.windcode;
tInfo.stopdays = w.wss(cCodes,'susp_days',wssDateArg);
% 没有中基协行业代码，暂用申万二级行业代替
tInfo.indcode = w.wss(cCodes,'indexcode_sw',wssDateArg,'industryType=2');
tInfo.indcode = w.wss(cCodes,'industry_CSRCcode12','industryType=3',wssDateArg);
tInfo = tInfo(tInfo.stopdays>0,:);
tInfo.seccode = cellfun(@(x)str2double(x(2:3)),tInfo.indcode);
tInfo = join(tInfo,tAMAC);
% tInfo.status = w.wss(cCodes,'trade_status',wssDateArg,'industryType=2');

% tAllInfo = tInfo;
% bStop = cellfun(@(x)~isempty(strfind(x,'停牌')),tInfo.status);
% bStop = strcmp(tInfo.status,'停牌一天');

bStop = tInfo.stopdays>0;
tInfo = tInfo(bStop,:);

%% 停牌调整价格计算
nCodes = numel(tInfo.stopdays);
tInfo.start = nan(nCodes,1);
tInfo.indclss = nan(nCodes,1);
% tInfo.indclse = nan(nCodes,1);
tInfo.sclss = w.wss(tInfo.windcode,'close',wssDateArg);

tpc = unique(tInfo.amaccode);
tpclose = w.wss(tpc,'close',wssDateArg);
tptclose = table(tpc,tpclose);
tptclose.Properties.VariableNames = {'amaccode','indclse'};
tInfo = join(tInfo,tptclose);

for iCode = 1:nCodes
    tpStartDate = double(zjx.tradingdate(dToday,-tInfo.stopdays(iCode)));
%     try
    tpStartDateArg = ['tradeDate=' datestr(tpStartDate,'yyyymmdd')];
    tInfo.start(iCode) = tpStartDate;
    tInfo.indclss(iCode) = w.wss(tInfo.amaccode(iCode),'close',tpStartDateArg);
%     tInfo.indclse(iCode) = w.wss(tInfo.amaccode(iCode),'close',wssDateArg);
%     catch
%         1;
%     end
end

tInfo.sclse = tInfo.sclss.*tInfo.indclse./tInfo.indclss;

%% 取出所有产品持仓，计算停牌影响并更新AccountDetail中的对应字段
tPosition = jst.getJasperPosition;
tPosition = innerjoin(tPosition,tInfo(:,{'windcode','sclss','sclse'}));
tPosition.stopadj = tPosition.qty.*(tPosition.sclse - tPosition.sclss);

tAccounts = table(unique(tPosition.account));
tAccounts.Properties.VariableNames = {'id'};
nAs = numel(tAccounts.id);
tAccounts.adjamt = zeros(nAs,1);
for iA = 1:nAs
    tAccounts.adjamt(iA) = sum(tPosition.stopadj(strcmpi(tPosition.account,tAccounts.id{iA})));
end

tAccDtl = jst.getAccountDetail();
tAccDct = jst.getAccountDict();

tAccounts = innerjoin(tAccounts,tAccDtl);
tAccounts = innerjoin(tAccounts,tAccDct);
tAccounts = tAccounts(:,{'trddt','id','name','totalasset','adjamt'});
tAccounts.adjbps = tAccounts.adjamt./tAccounts.totalasset*10000;

% 数据数据库update
nAccounts = numel(tAccounts.id);
conn = jst.irdbadmin;

chYYYYMMDD = datestr(dToday,'yyyymmdd');
for iA = 1:nAccounts
    tpid = tAccounts.id{iA} ;
    tpadj = tAccounts.adjbps(iA) ;
    sqlState = ['update [JasperDB].dbo.accountdetail set navadj1 = ' num2str(tpadj) ' where account = ''' tpid ''' and trade_dt = ' chYYYYMMDD];
    
    curs = exec(conn,sqlState);
    
    if isstruct(curs)
        error(['数据库连接出错：',curs.Message]);
    end
end
close(conn);
output = tAccounts;

tInfo.sadj = (tInfo.sclse./tInfo.sclss-1)*10000;

end