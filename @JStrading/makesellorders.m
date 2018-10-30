function makesellorders(chFile,tOrders)
if numel(unique(tOrders.account))>1
    error('bad input: too many accounts')
else
    chAccount = tOrders.account{1};
end
if any(tOrders.qty>0)
    error('bad input: long orders detected')
end

% tInfo = JStrading.getproductinfo; % �Ժ������ϵ�һ�ű�
tInfo = JStrading.getforbidinfo;

if any(strcmpi(tInfo.id,chAccount))
    tpTradeType = tInfo.tradeplatform{strcmpi(tInfo.id,chAccount)};
else
    return
end

tOrders.stockcode = cellfun(@(x)x(1:6),tOrders.windcode,'UniformOutput',false);

switch tpTradeType
    case 'fc' % һ��
        tOrders.stockcode = cellfun(@(x) ['''' x],tOrders.stockcode,'UniformOutput',false);
        tOrders.price = repmat({'��һ'},numel(tOrders.windcode),1);
        tOrders = tOrders(:,{'stockcode','name','qty','price'});
        cOrders = [{'����','����','����','�۸�'};table2cell(tOrders)];
        chFile = [chFile '.xls'];
        if exist(chFile,'file')
            delete(chFile)
        end
        xlswrite(chFile,cOrders)
    case 'hr' % ��������
        tOrders.buy = repmat({'��һ��'},numel(tOrders.windcode),1);
        tOrders.sell = repmat({'��һ��'},numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders = tOrders(:,{'stockcode','name','qty','buy','sell'});
        cOrders = table2cell(tOrders);
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    case 'o32' % ����O32���Ͷ
        tOrders.market = cellfun(@(x)strcmpi(x(end-1:end),'sz'),tOrders.windcode);
        tOrders.market = double(tOrders.market) + 1;
        tOrders.direction = 2*ones(numel(tOrders.windcode),1);
        tOrders.pricetype = 6*ones(numel(tOrders.windcode),1);
        tOrders.price = zeros(numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders.orderamt = zeros(numel(tOrders.windcode),1);
        
        tOrders = tOrders(:,{'stockcode','name','market','direction','pricetype','price','qty','orderamt'});
        cOrders = [{'����','����','�����г�','ί�з���','�۸�����','ί�м۸�','ί������','ί�н��'};table2cell(tOrders)];
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    case 'xt' % ѶͶ
        tOrders.price = ones(numel(tOrders.windcode),1);
        tOrders.weight = zeros(numel(tOrders.windcode),1);
        tOrders.qty = -tOrders.qty;
        tOrders = tOrders(:,{'stockcode','name','qty','weight','price'});
        cOrders = [{'����','����','����','Ȩ��','����'};table2cell(tOrders)];
        chFile = [chFile '.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end
        Utilities_zjx.cell2csv(chFile,cOrders)
    otherwise
        warning(['����ϵͳ' tpTradeType 'δָ���µ���ʽ��'])
end

end