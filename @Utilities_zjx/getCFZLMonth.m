function tInfo = getCFZLMonth(cCode)
% 获取各品种主力合约活跃月份。
% 
% - by Lary 2016.11.07

dAll = 1:12;

tpCell = { 
'A'	[1 5 9]
'AG'	[6 12]
'AL'	dAll
'AU'	dAll
'B'	dAll
'BB'	dAll
'BU'	[12 6]
'C'	[1 5 9]
'CF'	[1 5 9]
'CS'	[1 5 9]
'CU'	dAll
'FB'	dAll
'FG'	[1 5 9]
'FU'	dAll
'HC'	[1 5 10]
'I'	[1 5 9]
'J'	[1 5 9]
'JD'	[1 5 9]
'JM'	[1 5 9]
'JR'	dAll
'L'	[1 5 9]
'LR'	dAll
'M'	[1 5 9]
'MA'	[1 5 9]
'NI'	[1 5 9]
'OI'	[1 5 9]
'P'	[1 5 9]
'PB'	dAll
'PM'	dAll
'PP'	[1 5 9]
'RB'	[1 5 10]
'RI'	dAll
'RM'	[1 5 9]
'RS'	dAll
'RU'	[1 5 9]
'SF'	dAll
'SM'	[1 5 9]
'SN'	[1 5 9]
'SR'	[1 5 9]
'TA'	[1 5 9]
'V'	[1 5 9]
'WH'	dAll
'WR'	dAll
'Y'	[1 5 9]
'ZC'	[1 5 9]
'ZN'	dAll};

tInfo = cell2table(tpCell);
tInfo.Properties.VariableNames = {'Code'	'ZLMonth'};
if exist('cCode','var')
    tInfo = tInfo.ZLMonth{strcmpi(tInfo.Code,cCode)};
end
end