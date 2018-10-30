function output = getZLHY4Cons(cCodes,dDate)
% 获取主力合约
% 

if nargin == 0
    cCodes = {'RB'};
    dDate = today();
end
if nargin == 1
    dDate = today();
end
if isa(cCodes,'char')
    cCodes = cellstr(cCodes);
end

w = windmatlab;
% 生成当前合约YYMM
tMonths = Utilities_zjx.getCFZLMonth;
tpThisM = month(dDate);
tpThisY = year(dDate);

nCodes = numel(cCodes);
cCodesNear = cell(nCodes,1);
cCodesFar = cell(nCodes,1);
output = cell(nCodes,1);
for iCode = 1:nCodes;
    tpMonth = tMonths.ZLMonth{strcmpi(tMonths.Code,cCodes{iCode})};
    tpix = find(tpMonth>tpThisM);
    if isempty(tpix)
        tpix = 1;
        tpM1 = tpMonth(tpix);
        tpM2 = tpMonth(tpix+1);
        tpY1 = tpThisY+1;
        tpY2 = tpThisY+1;
    else
        tpix = tpix(1);
        if tpix == numel(tpMonth)
            tpM1 = tpMonth(tpix);
            tpM2 = tpMonth(1);
            tpY1 = tpThisY;
            tpY2 = tpThisY+1;
        else
            tpM1 = tpMonth(tpix);
            tpM2 = tpMonth(tpix+1);
            tpY1 = tpThisY;
            tpY2 = tpThisY;
        end
    end
    cCodesNear{iCode} = [cCodes{iCode} num2str(mod(tpY1,100),'%02d') num2str(tpM1,'%02d')];
    cCodesFar{iCode} = [cCodes{iCode} num2str(mod(tpY2,100),'%02d') num2str(tpM2,'%02d')];
end
cCodesNear = Utilities_zjx.getwindcode(cCodesNear);
cCodesFar = Utilities_zjx.getwindcode(cCodesFar);
% 判断到期日
dLtrddt = w.wss(cCodesNear,'lasttrade_date');
dLtrddt = datenum(dLtrddt,'yyyy/mm/dd');
tpDate = Utilities_zjx.tradingdate(dDate,30);
bFar = tpDate>dLtrddt;
output = cCodesNear;
output(bFar) = cCodesFar(bFar);

% 生成正确的主力合约

% 结束

end