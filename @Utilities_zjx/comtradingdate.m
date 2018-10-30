function dDates = comtradingdate(dDates)

nDates = numel(dDates);
for iDate = 1:nDates
    if hour(dDates(iDate))>16
        dDates(iDate) = Utilities_zjx.tradingdate(fix(dDates(iDate)),1);
    elseif hour(dDates(iDate))<9 && ~Utilities_zjx.istradingdate(fix(dDates(iDate)))
        dDates(iDate) = Utilities_zjx.tradingdate(fix(dDates(iDate)),1);
    end
end
dDates = fix(dDates);
end