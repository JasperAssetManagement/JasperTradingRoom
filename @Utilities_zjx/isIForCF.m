function     [IFFlag,FuCode] =  isIForCF(HYCode)
% �ж������Լ��IF����CF 
% IFFlag =1 ,˵��������ǹ�ָ
% ͬʱ���ݺ�Լ���롣�����Ʒ�ֵĴ��룬����IF1501��Ʒ�ּ���ΪIF
% 

CFFuInfo = Utilities_zjx.getCFFuInfoAll;
CFTradingCode = union(CFFuInfo.Code,CFFuInfo.OldCode);
IFFuInfo = Utilities_zjx.getIFFuInfoAll;
IFTradingCode = IFFuInfo.Code;

% ������ʽ ��ȡIC1501ǰ���IC 
[StartIndex,EndIndex] =  regexpi(HYCode,'[A-Za-z][A-Za-z]?');
FuCode = HYCode(StartIndex:EndIndex);
switch upper(FuCode)
    case CFTradingCode % ������� ��Ʒ�ڻ���Լ
       IFFlag = false;
    case IFTradingCode   % ������� ��ָ�ڻ���Լ
       IFFlag = true;
    otherwise
        error('����ĺ�Լ������ִ���');
end