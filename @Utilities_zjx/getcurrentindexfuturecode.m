function cCodes = getcurrentindexfuturecode(dToday)
zjx = Utilities_zjx;
if nargin == 0
    dToday = today;
end
dThisSettle = zjx.getifsettledate(year(dToday),month(dToday));
bSettled = dToday>dThisSettle;
if bSettled
    dCM = month(dToday)+1; % dCM = current month; dCY = current year
%     dCY = year(dToday) + double(dCM>12);
%     dCM = double(dCM<=12)*dCM + double(dCM>12)*mod(dCM,12);
else
    dCM = month(dToday);
end
dCY = year(dToday);

switch dCM
    case {1 4 7 10 13}
        dMonths = [dCM dCM+1 dCM+2 dCM+5]';
    case {2 5 8 11}
        dMonths = [dCM dCM+1 dCM+4 dCM+7]';
    case {3 6 9 12}
        dMonths = [dCM dCM+1 dCM+3 dCM+6]';
end

dYears = dCY + double(dMonths>12);
dMonths(dMonths>12) = mod(dMonths(dMonths>12),12);
dDays = ones(4,1);
dDates = datenum(dYears,dMonths,dDays);

dIFstart = datenum(2010,05,01);
dICstart = datenum(2015,05,01);
dIHstart = datenum(2015,05,01);

cIFYMs = unique(cellstr(datestr(dDates(dDates>=dIFstart),'yymm')));
cICYMs = unique(cellstr(datestr(dDates(dDates>=dICstart),'yymm')));
cIHYMs = unique(cellstr(datestr(dDates(dDates>=dIHstart),'yymm')));

cIFcodes = cellfun(@(x)['IF' x '.CFE'],cIFYMs,'UniformOutput',false);
cICcodes = cellfun(@(x)['IC' x '.CFE'],cICYMs,'UniformOutput',false);
cIHcodes = cellfun(@(x)['IH' x '.CFE'],cIHYMs,'UniformOutput',false);

cCodes = [cIFcodes;cICcodes;cIHcodes];

end