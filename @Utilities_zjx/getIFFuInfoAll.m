function IFFuInfo = getIFFuInfoAll()
%% 获取所有 金融期货 品种信息
%  IF IH IC TF T
% 类似于 getCFFuInfoAll 
% - by 谢亚
%      Lary 2016.10.31: 更新了最新的交易所手续费标准

FuInfoAllCell = {
    'IF'	'IF'	'沪深300'	'沪深300'	'CFE'	'中金所'	300	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'IH'	'IH'	'上证50'	'上证50'	'CFE'	'中金所'	300	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'IC'	'IC'	'中证500'	'中证500'	'CFE'	'中金所'	200	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'TF'	'TF'	'五债'	'五债'	'CFE'	'中金所'	10000	0.015	0.025	0	3	3	0.005	0
    'T'	'T'	'十债'	'十债'	'CFE'	'中金所'	10000	0.025	0.025	0	3	0	0.005	0};

IFFuInfo = cell2table(FuInfoAllCell);
IFFuInfo.Properties.VariableNames = {'Code'	'OldCode' 'WenhuaName' 'Name'	'ExchangeCode'	'Exchange'	'TradingUnit' 'Margin' 'MaxMargin' 'TCostType'	'TCostRatio'    'TCostRatio2' 'MinUnitChange' 'isNightTrading'};
