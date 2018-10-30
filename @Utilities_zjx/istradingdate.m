function bTradingDate = istradingdate(dToday) % 判断是否为交易日
    if numel(dToday) == 1
        bTradingDate = dToday == Utilities_zjx.tradingdate(dToday);
    else
        bTradingDate = ismember(dToday,Utilities_zjx.tradingdate([],[],'start',min(dToday),'end',max(dToday)));
    end
end