function tInfo = getwindfuinfo()
% 在getFuInfoAll的基础上
% 相关cellstr 转换成了 categorial类型，这样方便比较
% - by Lary 2016.10.26

% getFuInfoAll
FuInfo1 = Utilities_zjx.getCFFuInfoAll();
FuInfo2 = Utilities_zjx.getIFFuInfoAll();
tInfo = [FuInfo1;FuInfo2];

% get wind info
% try
    w = windmatlab;
    cWindCodes = Utilities_zjx.getwindcode(tInfo.Code);
    cDeliveryMonths = w.wss(cWindCodes,'cdmonths');
    cCMinfo = [tInfo.Code,cDeliveryMonths];
    tCMinfo = cell2table(cCMinfo,'VariableNames',{'Code','DeliveryMonth'});
    tInfo = join(tInfo,tCMinfo);
% catch err
%     warning('cannot connect to wind API.')
% end

% convert to categorical data type
tInfo.Code = categorical(tInfo.Code);
tInfo.Name = categorical(tInfo.Name);
tInfo.ExchangeCode = categorical(tInfo.ExchangeCode);
tInfo.Exchange = categorical(tInfo.Exchange);
tInfo.OldCode = categorical(tInfo.OldCode);
