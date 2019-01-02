function insert_trade_dates_2_80db()
    if ~exist('TradingDates','var')
        load('TradingDates.mat')
    end
    %Ð´ÈëÊý¾Ý¿â
    jtr=JasperTradingRoom;
    conn=jtr.db80pgconn;
    firstDate=min([TradingDates.SZ(1),TradingDates.HK(1),TradingDates.NY(1)]);
    lastDate=max([TradingDates.SZ(end),TradingDates.HK(end),TradingDates.NY(end)]);

    inputData=[];

    for i=firstDate:lastDate
        tpd=[{datestr(i,'yyyymmdd')}];
        if sum(i==TradingDates.SZ)==1
            tpd=[tpd, {'1'}];       
        else
            tpd=[tpd, {'0'}];     
        end

        if sum(i==TradingDates.SH)==1
            tpd=[tpd, {'1'}];       
        else
            tpd=[tpd, {'0'}];     
        end

        if sum(i==TradingDates.HK)==1
            tpd=[tpd, {'1'}];       
        else
            tpd=[tpd, {'0'}];     
        end

        if sum(i==TradingDates.NY)==1
            tpd=[tpd, {'1'}];       
        else
            tpd=[tpd, {'0'}];     
        end
        inputData=[inputData; tpd];
    end
    res = Utilities.upsert(conn,'jtder.public.trade_dates',{'trade_dt','sz','sh','hk','ny'},{'trade_dt'},inputData); 
    fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
end