for i=datenum('20180928','yyyymmdd'):datenum('20181011','yyyymmdd')
    s_date = datestr(i,'yyyymmdd');
    if Utilities.isTradingDates(s_date)
       JasperTradingRoom.genBoothbayPosition(s_date,'T01A');
    end
end