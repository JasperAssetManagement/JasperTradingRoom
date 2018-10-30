function cCodes = getpastindexfuturecode(dToday)
zjx = Utilities_zjx;
if nargin == 0
    dToday = today;
end
dThisSettle = zjx.getifsettledate(year(dToday),month(dToday));
if dToday<=dThisSettle
    dEnd = datenum(year(dToday),month(dToday),1)-1;
else
    dEnd = datenum(year(dToday),month(dToday)+1,1)-1;
end

dIFstart = datenum(2010,05,01);
dICstart = datenum(2015,05,01);
dIHstart = datenum(2015,05,01);

dDates = dIFstart:25:dEnd;
cIFYMs = unique(cellstr(datestr(dDates(dDates>=dIFstart),'yymm')));
cICYMs = unique(cellstr(datestr(dDates(dDates>=dICstart),'yymm')));
cIHYMs = unique(cellstr(datestr(dDates(dDates>=dIHstart),'yymm')));

cIFcodes = cellfun(@(x)['IF' x '.CFE'],cIFYMs,'UniformOutput',false);
cICcodes = cellfun(@(x)['IC' x '.CFE'],cICYMs,'UniformOutput',false);
cIHcodes = cellfun(@(x)['IH' x '.CFE'],cIHYMs,'UniformOutput',false);

cCodes = [cIFcodes;cICcodes;cIHcodes];

end