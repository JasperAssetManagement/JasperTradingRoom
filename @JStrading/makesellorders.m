function makesellorders(chFile,tOrders)
if numel(unique(tOrders.account))>1
    error('bad input: too many accounts')
else
    chAccount = tOrders.account{1};
end
if any(tOrders.qty>0)
    error('bad input: long orders detected')
end

% tInfo = JStrading.getproductinfo; % 以后再整合到一张表
tInfo = JStrading.getforbidinfo;

if any(strcmpi(tInfo.id,chAccount))
    tpTradeType = tInfo.tradeplatform{strcmpi(tInfo.id,chAccount)};
else
    return
end

tOrders.stockcode = cellfun(@(x)x(1:6),tOrders.windcode,'UniformOutput',false);

switch tpTradeType
    case 'fc' % 一创
        tOrders.stockcode = cellfun(@(x) ['''' x],tOrders.stockcode,'UniformOutput',false);
        tOrders.price = repmat({'卖一'},numel(tOrders.windcode),1);
        tOrders = tOrders(:,{'stockcode','name','qty','price'});
        cOrders = [{'代码','名称','数量','价格'};table2cell(tOrders)];
        chFile = [chFile '.xls'];
        if exist(chFile,'file')
            delete(chFile)
        end
        xlswrite(chFile,cOrders)
    case 'hr' % 华润信托
        tOrders.buy = repmat({'买一价'},numel(tOrders.windcode),1);
        tOrders.sell = repmat({'卖一价'},numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders = tOrders(:,{'stockcode','name','qty','buy','sell'});
        cOrders = table2cell(tOrders);
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    case 'o32' % 恒生O32或恒投
        tOrders.market = cellfun(@(x)strcmpi(x(end-1:end),'sz'),tOrders.windcode);
        tOrders.market = double(tOrders.market) + 1;
        tOrders.direction = 2*ones(numel(tOrders.windcode),1);
        tOrders.pricetype = 6*ones(numel(tOrders.windcode),1);
        tOrders.price = zeros(numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders.orderamt = zeros(numel(tOrders.windcode),1);
        
        tOrders = tOrders(:,{'stockcode','name','market','direction','pricetype','price','qty','orderamt'});
        cOrders = [{'代码','名称','交易市场','委托方向','价格类型','委托价格','委托数量','委托金额'};table2cell(tOrders)];
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    case 'xt' % 讯投
        tOrders.price = ones(numel(tOrders.windcode),1);
        tOrders.weight = zeros(numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders = tOrders(:,{'stockcode','name','qty','weight','price'});
        cOrders = [{'代码','名称','数量','权重','方向'};table2cell(tOrders)];
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    otherwise
        warning(['交易系统' tpTradeType '未指定下单格式。'])
end

end