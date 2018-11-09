%% flag zone
f_getData=1;
f_calPnl=1;%计算PnL
f_calTrading=0; %对当日的成交数据进行统计，并自动发送邮件
f_addFunc=0;%Boothbay持仓生成
f_loadFu=0;%导入期货权益
w=windmatlab;
% s_date=datestr(today(),'yyyymmdd');
s_date='20181031';
[w_data]=w.tdaysoffset(-1,s_date);
s_ydate=datestr(w_data,'yyyymmdd');

if 1==f_getData
   sqlstr=strcat('SELECT left(a.[S_INFO_WINDCODE],6),a.[S_DQ_PRECLOSE],a.[S_DQ_CLOSE],a.[S_DQ_PCTCHANGE]/100, b.[S_VAL_MV]/10000 FROM [WINDFILESYNC].[dbo].[ASHAREEODPRICES] a,',...
        '[WINDFILESYNC].[dbo].[ASHAREEODDERIVATIVEINDICATOR] b where a.TRADE_DT=b.TRADE_DT and a.S_INFO_WINDCODE=b.S_INFO_WINDCODE and a.TRADE_DT=''', ...
        s_date,''' order by a.S_INFO_WINDCODE;');
   data=DBExcutor85(sqlstr);
   if isempty(data)
       fprintf('Error(%s): DB prices of %s has not updated.',datestr(now(),0),s_date);
       f_calPnl=0;
       f_loadFu=0;
   else
       pctChg.codes=data(:,1);
       pctChg.pctchanges=cell2mat(data(:,4));
       closePrice.codes=data(:,1);
       closePrice.preprices=cell2mat(data(:,2));
       closePrice.prices=cell2mat(data(:,3)); 
       closePrice.mvs=cell2mat(data(:,5));
   end 
end

if 1==f_calPnl
    stress=280;%需要每日都填入模型的Stress
    pnl64=0;%来自Jimmy的数据，坐标系期货账户
    f_calPartOfAccounts=1;%计算部分账户
    f_adjustCapitals=0;%调整对应账户的规模
    f_updateDB=1;
    subAccounts=['90'];%计算部分账户时对应的产品ID
    aCap.accounts=['T02A'];%对应需要调整规模账户的ID
    aCap.capitals=[9849517];
    % 计算pos trading pnl
    [flag]=CalDailyPositionPL(s_date,s_ydate,stress,pctChg,closePrice,...
        f_calPartOfAccounts,subAccounts,f_adjustCapitals,aCap,f_updateDB,w);
    fprintf('flag: %s \n',flag);    
	
%   CalDailyTradeEffiency(s_date);

end

if 1==f_calTrading
   sqlstr=strcat('SELECT a.[S_INFO_WINDCODE],b.s_info_name,[S_DQ_CLOSE],[S_DQ_AMOUNT]*1000 ',...
        'FROM [WINDFILESYNC].[dbo].[ASHAREEODPRICES] a, [WINDFILESYNC].[dbo].[AShareDescription] b where a.S_INFO_WINDCODE=b.S_INFO_WINDCODE and TRADE_DT=''', ...
        s_date,''' order by S_INFO_WINDCODE;');
   data=DBExcutor85(sqlstr);
   if isempty(data)
       fprintf('Error(%s): DB prices of %s has not updated.',datestr(now(),0),s_date);
       f_calPnl=0;
       f_loadFu=0;
   else      
       closePrice.codes=data(:,1);
       closePrice.names=data(:,2);
       closePrice.prices=cell2mat(data(:,3));
       closePrice.amounts=cell2mat(data(:,4));     
   end    
   
   log = tradingStatistics(s_date,s_ydate,closePrice);
   add = strcat('dox.wang@jasperam.com;mei.shi@jasperam.com;jason.jiang@jasperam.com;bill.liu@jasperam.com;peter.ye@jasperam.com;harold.huang@jasperam.com;', ...
       'anty.wang@jasperam.com;neo.lin@jasperam.com;kathy.weng@jasperam.com;zhifeng.zhang@jasperam.com;bo.huang@jasperam.com;jie.du@jasperam.com');
   %add = 'neo.lin@jasperam.com;hardy.wong@jasperam.com';
   to=regexp(add,';','split');
  
   subject=strcat('交易情况统计_',s_date);
   sendMail(to,subject,log);
end

if 1==f_loadFu
    f_updateDB=1;
    ImportFutureInfo('\\192.168.1.88\Trading Share\DailyFutureDetail',s_date,f_updateDB);
    %历史数据备份
    chSource = '\\192.168.1.88\Trading Share\DailyFutureDetail\';
    chTgt = '\\192.168.1.88\Trading Share\Neo\backup\';
    sDir = dir(chSource);
    bGood = arrayfun(@(x)~x.isdir,sDir);
    sDir = sDir(bGood);
    nFiles = numel(sDir);
    for iFile = 1:nFiles
        if strfind(sDir(iFile).name,'~$')
            continue % ignore temp file
        end
        tpSource = [chSource sDir(iFile).name];
        tpTgt = [chTgt sDir(iFile).name];
        movefile(tpSource,tpTgt);
    end
        to='andy.wang@jasperam.com';  
	subject=strcat('持仓已导好_',s_date);
	sendMail(to,subject,'');
end
if 1==f_addFunc
    if Utilities.isTradingDates(s_date,'HK')
       JasperTradingRoom.calHksReturn(s_date);
    end
%     JasperTradingRoom.calAShareReturn(s_date,'JASON');
    ids = {'88';'86';'T01A';'T02A';'T03A'};%'88';'86';'T01A';'T02A';'T03A'
    for i=1:length(ids)
        s_id=ids{i};
        JasperTradingRoom.genBoothbayPosition(s_date,s_id);
    end
end
w.close;