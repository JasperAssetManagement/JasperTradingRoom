function bTradingDate = istradingdate(dToday) % �ж��Ƿ�Ϊ������
    if numel(dToday) == 1
        bTradingDate = dToday == Utilities_zjx.tradingdate(dToday);
    else
        bTradingDate = ismember(dToday,Utilities_zjx.tradingdate([],[],'start',min(dToday),'end',max(dToday)));
    end
end