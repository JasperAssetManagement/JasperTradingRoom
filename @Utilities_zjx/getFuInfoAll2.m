function FuInfoTable = getFuInfoAll2()
% 在getFuInfoAll的基础上
% 相关cellstr 转换成了 categorial类型，这样方便比较
% - by 谢亚

% getFuInfoAll
FuInfo1 = Utilities_zjx.getCFFuInfoAll();
FuInfo2 = Utilities_zjx.getIFFuInfoAll();
FuInfoTable = [FuInfo1;FuInfo2];

% 
FuInfoTable.Code = categorical(FuInfoTable.Code);
FuInfoTable.Name = categorical(FuInfoTable.Name);
FuInfoTable.ExchangeCode = categorical(FuInfoTable.ExchangeCode);
FuInfoTable.Exchange = categorical(FuInfoTable.Exchange);
FuInfoTable.OldCode = categorical(FuInfoTable.OldCode);