function insertOtherOrder(input)
% 输入格式：input = [2 2.28]; % 格式是每一行第一个变量为股票代码 第二个数为权重
% by Lary 2017.06.27

if ~exist('input','var')
    input = []; % 如果今天没有买单 用空值跑一遍
end

dVolLimitRatio = 0.1; % 合计卖出量占过去10日日均成交量的10%

w = windmatlab;
jst = JStrading;
zjx = Utilities_zjx;
conn = jst.dbconn;

dToday = today;

tped = Utilities_zjx.tradingdate(dToday-1);
tptd = Utilities_zjx.tradingdate(tped,1);
tpsd = Utilities_zjx.tradingdate(tped,-10);
tpche = datestr(tped,'yyyymmdd');
tpcht = datestr(tptd,'yyyymmdd');
tpchs = datestr(tpsd,'yyyymmdd');
    
sqlState = ['SELECT [WindCode],[Name],[Ratio],[ModelName],[availabledays] FROM [JasperDB].[dbo].[JasperOtherOrder] where Trade_dt=''' tpche ''' and WindCode not in (select WindCode from [JasperDB].[dbo].JasperForbiddenStock where Account=''0'' and issell = ''TRUE'' and StartDt<=''' tpcht ''' and (EndDt>''' tpcht ''' or EndDt =''''))'];
% sqlState = ['SELECT [WindCode],[Name],[Ratio],[ModelName],[availabledays] FROM [JasperDB].[dbo].[JasperOtherOrder] where Trade_dt=''' tpche '''']; % 忽略禁止池。
cYstOrder = jst.getsqlrtn(conn,sqlState);
tYstOrder = cell2table(cYstOrder,'VariableNames',{'windcode','name','ratio','modelname','availabledays'});
tYstOrder.availabledays = max(tYstOrder.availabledays-1,0);

if ~isempty(input)

    tInputs = cell2table(num2cell(input),'VariableNames',{'windcode','ratio'});
    tInputs.windcode = zjx.getwindstockcode(tInputs.windcode);
    tInputs.ratio = tInputs.ratio/100;
    tInputs.close = w.wss(tInputs.windcode,'close');
    tInputs.name = w.wss(tInputs.windcode,'sec_name');
    tInputs.modelname = repmat({'DOX2'},size(input,1),1);

    %% 更新OtherOrder及OtherPosition表。


    tTodayOrder = tInputs(:,{'windcode','name','ratio','modelname'});
    tTodayOrder.availabledays = ones(size(tTodayOrder.name));
    
    tTodayOrder = cat(1,tTodayOrder,tYstOrder);
else
    tTodayOrder = tYstOrder;
end
tTodayOrder.trade_dt = repmat({tpcht},size(tTodayOrder,1),1);
sqlState = ['delete from JasperDB.dbo.JasperOtherOrder where Trade_dt=''' tpcht ''''];
jst.getsqlrtn(conn,sqlState);
datainsert(conn,'JasperDB.dbo.JasperOtherOrder',tTodayOrder.Properties.VariableNames,table2cell(tTodayOrder))

% if ~isempty(input)
% %% 非禁止买单汇总
% 
% sqlState = 'select account,totalasset from [JasperDB].dbo.accountdetail  where trade_dt = ';
% 
% conn = jst.dbconn;
% sqlState = [sqlState '''' datestr(tped,'yyyymmdd') ''''];
% cData = jst.getsqlrtn(conn,sqlState);
% close(conn)
% tAssets = cell2table(cData,'VariableNames',{'account','totalasset'});
% tInfo = JStrading.getforbidinfo;
% % tInfo = tInfo(strcmpi(tInfo.trader,'Lary'),:);
% tInfo.account = tInfo.id;
% tInfo = innerjoin(tInfo,tAssets);
% cBan = {'15','37','45','68','04','20','32','22','17','50'};
% cBan = {'68','04','20','32','22','17','50'};
% tInfo = tInfo(~ismember(tInfo.account,cBan),:);
% 
% tAssets = innerjoin(tAssets,tInfo);
% 
% dTotalAUM = sum(tAssets.totalasset);
% tpAvgAmt = w.wss(tInputs.windcode,'avg_amt_per','unit=1',['startDate=' tpchs],['endDate=' tpche]);
% tpAvgAmt = tpAvgAmt*dVolLimitRatio;
% tpBuyAmt = dTotalAUM.*tInputs.ratio;
% tpRatio = tpBuyAmt./tpAvgAmt;
% tpRatio(tpRatio<1) = 1;
% tInputs.ratio = tInputs.ratio./tpRatio;
% 
% tAssets.buyamt = fix(tAssets.totalasset*sum(tInputs.ratio));
% 
% tInfo = JStrading.getforbidinfo;
% tInfo = tInfo(strcmpi(tInfo.trader,'Lary'),:);
% tInfo.account = tInfo.id;
% tInfo = innerjoin(tInfo,tAssets);
% 
% tAssets = innerjoin(tAssets,tInfo);
% chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\DO买汇总-' tpcht '.csv'];
% if exist(chFile,'file')
%     delete(chFile)
% end
% Utilities_zjx.cell2csv(chFile,table2cell(tAssets(:,{'account','buyamt'})))

% nAccounts = numel(tInfo.trader);
% nStocks = numel(tInputs.windcode);
% for iA = 1:nAccounts
%     chAccount = tInfo.account{iA};
%     dAsset = tAssets.totalasset(iA);
%     tOrders = tInputs;
%     tOrders.account = repmat({chAccount},nStocks,1);
%     tOrders.qty = round(dAsset.*tOrders.ratio./tOrders.close/100)*100;
%     tOrders = tOrders(:,{'windcode','name','account','qty'});
%     if ~isempty(tOrders)
%     chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\' chAccount '-DO-' tpcht];
%     if exist(chFile,'file')
%         delete(chFile)
%     end
%     JStrading.makebuyorders(chFile,tOrders);
%     end
% end


%% 禁止池买单汇总
% cModelList = jst.getLatestModelList;
% tInputs = tInputs(~ismember(tInputs.windcode,cModelList),:);
% 
% tAssets.buyamt = fix(tAssets.totalasset*sum(tInputs.ratio));
% 
% 
% tInfo = JStrading.getforbidinfo;
% tInfo = tInfo(strcmpi(tInfo.trader,'Lary'),:);
% tInfo.account = tInfo.id;
% tInfo = innerjoin(tInfo,tAssets);
% 
% tAssets = innerjoin(tAssets,tInfo);
% chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\DOB买汇总-' tpcht '.csv'];
% if exist(chFile,'file')
%     delete(chFile)
% end
% Utilities_zjx.cell2csv(chFile,table2cell(tAssets(:,{'account','buyamt'})))
% 
% nAccounts = numel(tInfo.trader);
% nStocks = numel(tInputs.windcode);
% for iA = 1:nAccounts
%     chAccount = tInfo.account{iA};
%     dAsset = tAssets.totalasset(iA);
%     tOrders = tInputs;
%     tOrders.account = repmat({chAccount},nStocks,1);
%     tOrders.qty = round(dAsset.*tOrders.ratio./tOrders.close/100)*100;
%     tOrders = tOrders(:,{'windcode','name','account','qty'});
%     if ~isempty(tOrders)
%     chFile = ['C:\Users\DELL\Desktop\Models\下单汇总\' chAccount '-DOB-' tpcht];
%     if exist(chFile,'file')
%         delete(chFile)
%     end
%     JStrading.makebuyorders(chFile,tOrders);
%     end
% end

% end

jst.updateOtherPosition % 更新otherPosition

end