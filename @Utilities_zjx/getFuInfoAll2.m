function FuInfoTable = getFuInfoAll2()
% ��getFuInfoAll�Ļ�����
% ���cellstr ת������ categorial���ͣ���������Ƚ�
% - by л��

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