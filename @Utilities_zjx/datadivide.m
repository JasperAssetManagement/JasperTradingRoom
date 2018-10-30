function cData = datadivide(dData,dDates)
% datadivide是datamatch的反函数
% - by Lary 2016.08.23

nStocks = size(dData,2);
nDates = numel(dDates);
nDataDates = size(dData,1);
if nDates == nDataDates
    cData = cell(nStocks,1);
    for iStock = 1:nStocks
        tps.dates = dDates;
        tps.close = dData(:,iStock);
        cData{iStock} = tps;
    end
else
    cData = {};
end

end