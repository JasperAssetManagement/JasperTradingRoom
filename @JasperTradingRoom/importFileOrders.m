function importFileOrders(date,smodel)
%每日导入excel发送的交易单
% input：s_date: 输入日期,matlab整数型日期或者 'yyyymmdd'字符串型
%        smodel: 导入的模型名称
% 如果没有任何输入，则默认为today(),'JASON'
% 例: JasperTradingRoom.importFileOrders
% - Modified by Neo 2018.04.20

jtr = JasperTradingRoom;
utils = Utilities;

if ( nargin == 0 )
    date=datestr(today(),'yyyymmdd');
    smodel='JASON';
elseif ( nargin == 1 )
    if isnumeric(date)
        date=datestr(date,'yyyymmdd'); 
    end
    smodel='JASON';
elseif isnumeric(date)
    date=datestr(date,'yyyymmdd'); 
end
w=windmatlab;
if strcmp(smodel,'PETER')==1
    sfilepath=['\\192.168.1.75\ZForders\Peterorders\AllOrder ' date '.csv']; 
elseif strcmp(smodel,'JASON')==1
    sfilepath=['\\192.168.1.75\ZForders\Jasonorders\' date '.xlsx']; 
end
sDir=dir(sfilepath);
% torder=table({''},{''},{''},'VariableNames',{'account','windcode','qty'});
for i=1:length(sDir)    
    sfilepath=[sDir(i).folder '\' sDir(i).name];
    [accs, codes, nums] = utils.csvimport(sfilepath,'columns',{'strategy_id','symbol','volume'});
%     cols=strcmp(TXT(1,:),'symbol')==1;
%     codes=TXT(2:end,cols);      
%     cols=strcmp(TXT(1,:),'strategy_id')==1;
%     accs=TXT(2:end,cols);    
    codes(cellfun(@isempty,accs))=[];
    nums(cellfun(@isempty,accs))=[];
    accs(cellfun(@isempty,accs))=[];
    accs=cellfun(@(x) replace(char(x), '_PETER', ''), accs, 'uniformOutput', false);
    nums=cellfun(@(x) str2double(x), nums);
    tmp=table(accs,codes,nums,'VariableNames',{'account','windcode','qty'});
    if exist('torder','var')
        torder=[torder;tmp];
    else
        torder=tmp;
    end
end
dealorder(torder,smodel,date,jtr,w); 
w.close;
end

function [] = dealorder(torder,modelname,sdate,jtr,w)
%     [NUM,TXT] = xlsread(sfilepath,1);
%     cols=strcmp(TXT(1,:),'WindCode')==1;
%     codes=TXT(2:end,cols);  
%     cols=strcmp(TXT(1,:),'简称')==1;    
%     names=TXT(2:end,cols);    
%     cols=strcmp(TXT(1,:),'Account')==1;
%     accs=TXT(2:end,cols); 
    
%     torder=table(accs,codes,NUM,'VariableNames',{'account','windcode','qty'}); %,'name'
    code=unique(torder.windcode);
    name=w.wss(code,'sec_name');
    torder.name=cellfun(@(x) name(strcmp(x,code)==1),torder.windcode);
    torder.name(cellfun(@(x) any(isnan(x)),torder.name))={''};
    torder(torder.qty==0,:)=[];
    torder.trade_dt=repmat(sdate,size(torder,1),1);         
    %torder.account=cellfun(@(x) double2cell(sprintf('%02d',cell2mat(x))),accs);    
    torder.type=repmat('S',size(torder,1),1); 
    torder.side=ones(size(torder,1),1); 
    torder.side(torder.qty<0)=2;
    torder.modelname=repmat(modelname,size(torder,1),1);     
    conn=jtr.db88conn;
    res = Utilities.upsert(conn,'JasperDB.dbo.JasperOtherOrderByQty',torder.Properties.VariableNames,[1 0 0 1 1 0 1 1],table2cell(torder));  
    fprintf('upsert OtherOrderByQty(from file):insert %d,update %d \n',sum(res==1),sum(res==0));  
    
    code=unique(torder.windcode);
    close=w.wsd(code,'pre_close',date,date);
    torder.close=arrayfun(@(x) close(strcmp(x,code)==1),torder.windcode);
    %同时生成成交清单，更新到指令/指令明细表中
    accids=unique(torder.account);
    s_ydate=Utilities.tradingdate(datenum(sdate,'yyyymmdd'),-1,'outputStyle','yyyymmdd');
    cAccList=jtr.getaccounts(s_ydate);
    torder.stockcode=cellfun(@(x) x(1:6),torder.windcode,'un',0);
    torder.tradeqty=torder.qty;
    for i=1:length(accids)
        rows=strcmp(torder.account,accids(i))==1;
        cTrader=cAccList.traders{strcmp(cAccList.ids,accids(i))==1};
        sSystem=cAccList.systems{strcmp(cAccList.ids,accids(i))==1};
        fprintf('dealing with account: %s\n',accids{i});
%         JasperTradingRoom.makeorderfile(torder(rows,{'stockcode','name','tradeqty'}),accids{i},cTrader,sSystem,modelname);
        tins=cell2table({sdate,accids{i},modelname,sum(torder.qty(rows).*torder.close(rows))/10000,modelname,cTrader,sum(torder.qty(rows).*torder.close(rows))/10000}, ...
            'VariableNames',{'trade_dt','account','modelname','insparam','advisor','remark','realinsparam'});
        tpt=torder(rows,{'trade_dt','windcode','qty'});
        JasperTradingRoom.insertInstruction2DB(tins,tpt);
    end
    
end
