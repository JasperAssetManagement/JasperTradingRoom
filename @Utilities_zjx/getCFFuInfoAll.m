function FuInfoTable = getCFFuInfoAll()
% 这个Cell数组里面包含了所有商品期货品种的相关信息
% 更新了保证金要求 ，还有是否夜盘交易的标记
% 
% 类似的相关信息 保存在 Excel 文件当中，可以在Excel 文件中 修改相关的信息 ，然后复制到 这里
% 
% 这个里面的信息，非常重要，需要重复调用使用
% - by 谢亚
%      Lary 2016.08.03 update: 修正了鸡蛋和动力煤的合约乘数错误。
%                                   鸡蛋合约规模虽然为5吨，但单价为每500千克
%                                   动力煤合约规模为100吨
%      Lary 2016.10.31: 更新了最新的交易所手续费标准

FuInfoAllCell = { 
'A'	'A'	'豆一'	'豆一'	'DCE'	'大商所'	10	0.09	0.25	0	2	2	1	1
'AG'	'AG'	'沪银'	'沪银'	'SHF'	'上期所'	15	0.12	0.2	1	5.00E-05	5.00E-05	1	1
'AL'	'AL'	'沪铝'	'沪铝'	'SHF'	'上期所'	5	0.09	0.2	0	3	0	5	1
'AU'	'AU'	'沪金'	'沪金'	'SHF'	'上期所'	1000	0.1	0.2	0	10	0	0.05	1
'B'	'B'	'豆二'	'豆二'	'DCE'	'大商所'	10	0.09	0.25	0	2	2	1	1
'BB'	'BB'	'胶板'	'胶板'	'DCE'	'大商所'	500	0.24	0.25	1	5.00E-05	5.00E-05	0.05	0
'BU'	'BU'	'沥青'	'沥青'	'SHF'	'上期所'	10	0.12	0.2	1	0.0001	0.0001	2	1
'C'	'C'	'玉米'	'玉米'	'DCE'	'大商所'	10	0.09	0.25	0	0.6	0.6	1	0
'CF'	'CF'	'棉花'	'郑棉'	'CZC'	'郑商所'	5	0.09	0.25	0	6	6	5	1
'CS'	'CS'	'淀粉'	'淀粉'	'DCE'	'大商所'	10	0.09	0.25	0	1.5	1.5	1	0
'CU'	'CU'	'沪铜'	'沪铜'	'SHF'	'上期所'	5	0.12	0.2	1	5.00E-05	0	10	1
'FB'	'FB'	'纤板'	'纤板'	'DCE'	'大商所'	500	0.24	0.25	1	5.00E-05	5.00E-05	0.05	0
'FG'	'FG'	'玻璃'	'玻璃'	'CZC'	'郑商所'	20	0.09	0.25	0	3	3	1	1
'FU'	'FU'	'燃油'	'燃油'	'SHF'	'上期所'	50	0.24	0.24	1	2.00E-05	2.00E-05	1	0
'HC'	'HC'	'热卷'	'热卷'	'SHF'	'上期所'	10	0.1	0.2	1	0.0001	0.0001	1	1
'I'	'I'	'铁矿'	'铁矿'	'DCE'	'大商所'	100	0.1	0.25	1	0.0003	0.0003	0.5	1
'J'	'J'	'焦炭'	'焦炭'	'DCE'	'大商所'	100	0.09	0.25	1	0.00072	0.00072	0.5	1
'JD'	'JD'	'鸡蛋'	'鸡蛋'	'DCE'	'大商所'	10	0.12	0.25	1	0.00015	0.00015	1	0
'JM'	'JM'	'焦煤'	'焦煤'	'DCE'	'大商所'	60	0.09	0.25	1	0.00072	0.00072	0.5	1
'JR'	'JR'	'粳稻'	'粳稻'	'CZC'	'郑商所'	20	0.09	0.25	0	3	3	1	0
'L'	'L'	'塑料'	'塑料'	'DCE'	'大商所'	5	0.1	0.25	0	2	2	5	0
'LR'	'LR'	'晚稻'	'晚稻'	'CZC'	'郑商所'	20	0.09	0.25	0	3	3	1	0
'M'	'M'	'豆粕'	'豆粕'	'DCE'	'大商所'	10	0.09	0.25	0	1.5	1.5	1	1
'MA'	'ME'	'郑醇'	'郑醇'	'CZC'	'郑商所'	10	0.11	0.25	0	1.4	1.4	1	1
'NI'	'NI'	'沪镍'	'沪镍'	'SHF'	'上期所'	1	0.12	0.2	0	6	6	10	1
'OI'	'RO'	'郑油'	'郑油'	'CZC'	'郑商所'	10	0.09	0.25	0	2.5	1.25	2	1
'P'	'P'	'棕榈'	'棕榈'	'DCE'	'大商所'	10	0.09	0.25	0	2.5	2.5	2	1
'PB'	'PB'	'沪铅'	'沪铅'	'SHF'	'上期所'	5	0.09	0.2	1	4.00E-05	0	5	1
'PM'	'WT'	'普麦'	'普麦'	'CZC'	'郑商所'	50	0.09	0.25	0	5	5	1	0
'PP'	'PP'	'PP'	'聚丙烯'	'DCE'	'大商所'	5	0.1	0.25	1	0.00024	0.00024	1	0
'RB'	'RB'	'螺纹'	'螺纹'	'SHF'	'上期所'	10	0.1	0.2	1	0.0001	0.0001	1	1
'RI'	'ER'	'早稻'	'早稻'	'CZC'	'郑商所'	20	0.09	0.25	0	2.5	2.5	1	0
'RM'	'RM'	'菜粕'	'菜粕'	'CZC'	'郑商所'	10	0.09	0.25	0	3	3	1	1
'RS'	'RS'	'菜籽'	'菜籽'	'CZC'	'郑商所'	10	0.09	0.25	0	2	2	1	0
'RU'	'RU'	'天胶'	'天胶'	'SHF'	'上期所'	10	0.12	0.2	1	4.50E-05	4.50E-05	5	1
'SF'	'SF'	'硅铁'	'硅铁'	'CZC'	'郑商所'	5	0.09	0.25	0	3	1.5	2	0
'SM'	'SM'	'锰硅'	'锰硅'	'CZC'	'郑商所'	5	0.09	0.25	0	3	1.5	2	0
'SN'	'SN'	'沪锡'	'沪锡'	'SHF'	'上期所'	1	0.09	0.2	0	3	0	10	1
'SR'	'SR'	'白糖'	'白糖'	'CZC'	'郑商所'	10	0.09	0.25	0	3	1.5	1	1
'TA'	'TA'	'PTA'	'PTA'	'CZC'	'郑商所'	5	0.09	0.25	0	3	1.5	2	1
'V'	'V'	'PVC'	'PVC'	'DCE'	'大商所'	5	0.09	0.25	0	1	1	5	0
'WH'	'WS'	'郑麦'	'郑麦'	'CZC'	'郑商所'	20	0.09	0.25	0	2.5	1.25	1	0
'WR'	'WR'	'线材'	'线材'	'SHF'	'上期所'	10	0.24	0.24	1	4.00E-05	4.00E-05	1	0
'Y'	'Y'	'豆油'	'豆油'	'DCE'	'大商所'	10	0.09	0.25	0	2.5	2.5	2	1
'ZC'	'TC'	'郑煤'	'动煤'	'CZC'	'郑商所'	100	0.09	0.09	0	6	6	0.2	1
'ZN'	'ZN'	'沪锌'	'沪锌'	'SHF'	'上期所'	5	0.1	0.2	0	3	0	5	1};

FuInfoTable = cell2table(FuInfoAllCell);
FuInfoTable.Properties.VariableNames = {'Code'	'OldCode' 'WenhuaName' 'Name'	'ExchangeCode'	'Exchange'	'TradingUnit' 'Margin' 'MaxMargin' 'TCostType'	'TCostRatio'    'TCostRatio2' 'MinUnitChange' 'isNightTrading'};
end