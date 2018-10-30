function     [IFFlag,FuCode] =  isIForCF(HYCode)
% 判断输入合约是IF还是CF 
% IFFlag =1 ,说明输入的是股指
% 同时根据合约代码。输出该品种的代码，比如IF1501的品种简码为IF
% 

CFFuInfo = Utilities_zjx.getCFFuInfoAll;
CFTradingCode = union(CFFuInfo.Code,CFFuInfo.OldCode);
IFFuInfo = Utilities_zjx.getIFFuInfoAll;
IFTradingCode = IFFuInfo.Code;

% 正则表达式 获取IC1501前面的IC 
[StartIndex,EndIndex] =  regexpi(HYCode,'[A-Za-z][A-Za-z]?');
FuCode = HYCode(StartIndex:EndIndex);
switch upper(FuCode)
    case CFTradingCode % 输入的是 商品期货合约
       IFFlag = false;
    case IFTradingCode   % 输入的是 股指期货合约
       IFFlag = true;
    otherwise
        error('输入的合约代码出现错误');
end