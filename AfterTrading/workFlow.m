f_calPnl=1;%����PnL
f_addFunc=0;%Boothbay�ֲ�����
w=windmatlab;
jtr=JasperTradingRoom;
s_date=datestr(today(),'yyyymmdd');
% s_date='20190913';
s_ydate=Utilities.tradingdate(datenum(s_date,'yyyymmdd'), -1, 'outputStyle','yyyymmdd');

if 1==f_calPnl    
    f_updateDB=1;
    
    f_adjustCapitals=0;%������Ӧ�˻��Ĺ�ģ
    aCap.accounts=['91';'85'];%��Ӧ��Ҫ������ģ�˻���ROOT_ID
    aCap.capitals=[1000000;2000000];    
    
    f_calPartOfAccounts=0;%���㲿���˻�
    subAccounts={'90','82'};%���㲿���˻�ʱ��Ӧ�Ĳ�ƷID   
    
    f_calHKDiffDay=0; %�Ƿ�ֻ����۹ɣ�һ��Ϊ0
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
    %��������˻�
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

    % ����pos trading pnl
    
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
