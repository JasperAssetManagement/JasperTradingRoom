function IFFuInfo = getIFFuInfoAll()
%% ��ȡ���� �����ڻ� Ʒ����Ϣ
%  IF IH IC TF T
% ������ getCFFuInfoAll 
% - by л��
%      Lary 2016.10.31: ���������µĽ����������ѱ�׼

FuInfoAllCell = {
    'IF'	'IF'	'����300'	'����300'	'CFE'	'�н���'	300	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'IH'	'IH'	'��֤50'	'��֤50'	'CFE'	'�н���'	300	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'IC'	'IC'	'��֤500'	'��֤500'	'CFE'	'�н���'	200	0.41	0.41	1	2.30E-05	0.0023	0.2	0
    'TF'	'TF'	'��ծ'	'��ծ'	'CFE'	'�н���'	10000	0.015	0.025	0	3	3	0.005	0
    'T'	'T'	'ʮծ'	'ʮծ'	'CFE'	'�н���'	10000	0.025	0.025	0	3	0	0.005	0};

IFFuInfo = cell2table(FuInfoAllCell);
IFFuInfo.Properties.VariableNames = {'Code'	'OldCode' 'WenhuaName' 'Name'	'ExchangeCode'	'Exchange'	'TradingUnit' 'Margin' 'MaxMargin' 'TCostType'	'TCostRatio'    'TCostRatio2' 'MinUnitChange' 'isNightTrading'};
