function tInfo = getIndexWeight(chCode,chDate)
if ~exist('chCode','var')
    chCode = '000016.SH';
end
if ~exist('chDate','var')
    chDate = datestr(Utilities_zjx.tradingdate(),'yyyy-mm-dd');
end

cData = w.wset('indexconstituent',['date=' chDate ';windcode=' chCode ';field=wind_code,i_weight');
tInfo = cell2table(cData,'VariableNames',{'windcode','weight'});
end