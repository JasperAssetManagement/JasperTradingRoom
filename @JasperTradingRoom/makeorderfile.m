function makeorderfile(torder,account,trader,system,model)
% 根据交易系统和交易员信息生成成交清单
% input:     
%   torder    成交明细(table)，最少包含两个字段'stockcode','tradeqty'(买卖区别正负号)
%   account   账户ID
%   trader    交易员，控制生成的文件位置 
%   system    交易系统，控制生成的文件格式
% 例: JasperTradingRoom.makeorderfile(torder,'01','Neo','迅投')
% by Neo - 2017.12.12 
if ~exist('model','var')
    model='';
else
    model = ['-' model];
end
switch system
    case '迅投'        
        torder=torder(:,{'stockcode','name','tradeqty'});
        torder.weight=zeros(size(torder,1),1);
        torder.side=zeros(size(torder,1),1);
        torder.side(torder.tradeqty<0,:)=1; %买 0 卖 1
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0);        
        corder=[{'代码','名称','数量','权重','方向'};table2cell(torder(torder.side==0,:))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
        corder=[{'代码','名称','数量','权重','方向'};table2cell(torder(torder.side==1,:))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
    case '一创机构通'
        torder.stockcode=cellfun(@(x) ['''' x],torder.stockcode,'un',0);
        torder=torder(:,{'stockcode','name','tradeqty'});        
        torder.price=repmat({'买一'},size(torder,1),1);
        torder.price(torder.tradeqty<0,:)={'卖一'}; %update：买卖用了本方价
        corder=[{'代码','名称','数量','价格'};table2cell(torder)];
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end  
        xlswrite(chFile,corder);
    case '恒生资管'
        torder=torder(:,{'stockcode','tradeqty'});  
        buyrows=torder.tradeqty>0;    
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        corder=[{'生效','','','','成分券代码','','','','','','数量'};cat(2,repmat({''},sum(buyrows),4),torder.stockcode(buyrows),...
            repmat({''},sum(buyrows),5),num2cell(torder.tradeqty(buyrows)))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,corder);
        corder=[{'生效','','','','成分券代码','','','','','','数量'};cat(2,repmat({''},sum(~buyrows),4),torder.stockcode(~buyrows),...
            repmat({''},sum(~buyrows),5),num2cell(torder.tradeqty(~buyrows)))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);  
    case 'o32'
        torder.stockcode=cellfun(@(x) ['''' x],torder.stockcode,'un',0);
        torder.side=ones(size(torder,1),1);
        torder.side(torder.tradeqty<0)=2;
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        torder.price=zeros(size(torder,1),1);
        torder.pricetype=repmat(5,size(torder,1),1);
        torder.market=repmat(2,size(torder,1),1);
        torder.market(cellfun(@(x) strcmp(x(2),'6'),torder.stockcode))=1;        
        
        torder=torder(:,{'stockcode','side','tradeqty','price','pricetype','market'});    
        buyrows=torder.side==1;
        corder=[{'证券代码','委托方向','指令数量','指令价格','价格模式','交易市场内部编号'};table2cell(torder(buyrows,:))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'证券代码','委托方向','指令数量','指令价格','价格模式','交易市场内部编号'};table2cell(torder(~buyrows,:))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);  
    case '恒投'
        torder.side=ones(size(torder,1),1);
        torder.side(torder.tradeqty<0)=2;
        torder.market=repmat(2,size(torder,1),1);
        torder.market(cellfun(@(x) strcmp(x(1),'6'),torder.stockcode))=1;
        torder.price=zeros(size(torder,1),1);
        torder.pricetype=repmat(6,size(torder,1),1);
        torder.amount=zeros(size(torder,1),1);
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        
        torder=torder(:,{'stockcode','name','market','side','pricetype','price','tradeqty','amount'});    
        buyrows=torder.side==1;
        corder=[{'证券代码','证券名称','交易市场','委托方向','价格类型','委托价格','委托数量','委托金额'};table2cell(torder(buyrows,:))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,corder);  
        corder=[{'证券代码','证券名称','交易市场','委托方向','价格类型','委托价格','委托数量','委托金额'};table2cell(torder(~buyrows,:))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
    case '投资赢家'
        torder.buy=repmat({'买一价'},size(torder,1),1);
        torder.sell=repmat({'卖一价'},size(torder,1),1);        
        torder=torder(:,{'stockcode','name','tradeqty','buy','sell'}); 
        buyrows=torder.tradeqty>0;
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,table2cell(torder(buyrows,:)));          
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,table2cell(torder(~buyrows,:)));     
    case '中金IMS'
        torder.stockcode=cellfun(@(x) ['''' x],torder.stockcode,'un',0);
        torder.market=ones(size(torder,1),1);
        torder.market(cellfun(@(x) strcmp(x(2),'6'),torder.stockcode))=0;
        torder.side=repmat('B',size(torder,1),1);
        torder.side(torder.tradeqty<0)='S';
        torder.postype=cell(size(torder,1),1); 
        torder.pricetype=zeros(size(torder,1),1); 
%         torder.getprice=repmat('T1',size(torder,1),1);
%         torder.price=zeros(size(torder,1),1);
        torder.remark=cell(size(torder,1),1);
        
        torder=torder(:,{'market','stockcode','side','postype','pricetype','tradeqty','remark'});  
        buyrows=torder.tradeqty>0;
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        corder=[{'市场','合约代码','委托方向','投机套保','价格限制','数量','备注'};table2cell(torder(buyrows,:))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'市场','合约代码','委托方向','投机套保','价格限制','数量','备注'};table2cell(torder(~buyrows,:))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);     
    case '广发PB'
        torder.stockcode=cellfun(@(x) ['''' x],torder.stockcode,'un',0);
        torder.side=repmat({'0B'},size(torder,1),1);
        torder.side(torder.tradeqty<0)={'0S'};
        torder.price=zeros(size(torder,1),1);
        torder.pricetype=repmat(5,size(torder,1),1);
        torder.market=zeros(size(torder,1),1);
        torder.market(cellfun(@(x) strcmp(x(2),'6'),torder.stockcode))=1;
        torder.invtype=cell(size(torder,1),1);
        torder.invflag=cell(size(torder,1),1);
        torder.accid=cell(size(torder,1),1);
        torder.unit=cell(size(torder,1),1);
        torder.subid=cell(size(torder,1),1);
        
        torder=torder(:,{'stockcode','side','tradeqty','price','pricetype','market','invtype','invflag','accid','unit','subid'});
        buyrows=torder.tradeqty>0;
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        corder=[{'证券代码','委托方向','指令数量','指令价格','价格模式','交易市场','投资类型','投保标志','产品编号','资产单元','组合编号'};table2cell(torder(buyrows,:))]; %生成买单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'证券代码','委托方向','指令数量','指令价格','价格模式','交易市场','投资类型','投保标志','产品编号','资产单元','组合编号'};table2cell(torder(~buyrows,:))]; %生成卖单
        chFile = ['\\192.168.1.88\Trading Share\' trader '\当日指令\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);  
    otherwise
        warning(['交易系统''' system '''未指定下单格式。'])
end
end