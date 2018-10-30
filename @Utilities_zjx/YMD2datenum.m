function [Datenum,Year,Month,Day] = YMD2datenum(dDates)
% dDates contains any size of date data with the format of YYYYMMDD, this
% funtion will convert it into matlab date numbers. Optional arguments are
% provided as the year, month and day number of the date vector.

% By Lary

Day = mod(dDates,100);
Month = (mod(dDates,10000)-Day)/100;
Year = floor(dDates/10000);

Datenum = datenum(Year,Month,Day);

end

