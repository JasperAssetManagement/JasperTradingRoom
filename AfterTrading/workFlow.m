f_calPnl=1;%计算PnL
f_addFunc=0;%Boothbay持仓生成
w=windmatlab;
jtr=JasperTradingRoom;
s_date=datestr(today(),'yyyymmdd');
% s_date='20190913';
s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'), -1, 'outputStyle','yyyymmdd');

if 1==f_calPnl    
    f_updateDB=1;
    
    f_adjustCapitals=0;%调整对应账户的规模
    aCap.accounts=['91';'85'];%对应需要调整规模账户的ROOT_ID
    aCap.capitals=[1000000;2000000];    
    
    f_calPartOfAccounts=0;%计算部分账户
    subAccounts={'90','82'};%计算部分账户时对应的产品ID   
    
    f_calHKDiffDay=0; %是否只计算港股，一般为0
    if 1==f_calHKDiffDay
        f_mergeAccount=0;
    else
        f_mergeAccount=1;
    end
    
    if 1==f_adjustCapitals        
        adjustAccT=table(aCap.accounts,aCap.capitals,'VariableNames',{'id','capital'});
    else
        adjustAccT=[];
    end
    account=jtr.getaccounts(s_ydate, adjustAccT);
    %计算个别账户
    if 1==f_calPartOfAccounts
        [isin,~]=ismember(account.id,subAccounts);
        dealAcc=account(isin==1,:);  
    else
        dealAcc=account;
    end 
    
    mergeAccount=containers.Map;
    if 1==f_mergeAccount
        mergeAccount('64')={'64A'};
        mergeAccount('80')={'80A','80B'};
        mergeAccount('85')={'85A','85B'};
        mergeAccount('93')={'93A','93B'};        
    end

    % 计算pos trading pnl
    
    CalDailyPositionPL(s_date,dealAcc,mergeAccount,f_updateDB,f_calHKDiffDay,w);
%     fprintf('flag: %s \n',flag);    
	
%     CalDailyTradeEffiency(s_date);
end

if 1==f_addFunc
    if Utilities.isTradingDates(s_date,'HK')
       JasperTradingRoom.calHksReturn(s_date);
    end
%     JasperTradingRoom.calAShareReturn(s_date,'JASON');
    ids = {'84JD';'86';'88';'93A';'93'}; %'55JD';'84JD';'85AJD';'91JD';'93AJD';'86';'88';'93A';'93'
    for i=1:length(ids)
        s_id=ids{i};
        JasperTradingRoom.genBoothbayPosition(s_date,s_id);
    end
end
w.close;
