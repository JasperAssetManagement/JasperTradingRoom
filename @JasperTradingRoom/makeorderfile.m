function makeorderfile(torder,account,trader,system,model)
% ���ݽ���ϵͳ�ͽ���Ա��Ϣ���ɳɽ��嵥
% input:     
%   torder    �ɽ���ϸ(table)�����ٰ��������ֶ�'stockcode','tradeqty'(��������������)
%   account   �˻�ID
%   trader    ����Ա���������ɵ��ļ�λ�� 
%   system    ����ϵͳ���������ɵ��ļ���ʽ
% ��: JasperTradingRoom.makeorderfile(torder,'01','Neo','ѸͶ')
% by Neo - 2017.12.12 
if ~exist('model','var')
    model='';
else
    model = ['-' model];
end
switch system
    case 'ѸͶ'        
        torder=torder(:,{'stockcode','name','tradeqty'});
        torder.weight=zeros(size(torder,1),1);
        torder.side=zeros(size(torder,1),1);
        torder.side(torder.tradeqty<0,:)=1; %�� 0 �� 1
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0);        
        corder=[{'����','����','����','Ȩ��','����'};table2cell(torder(torder.side==0,:))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
        corder=[{'����','����','����','Ȩ��','����'};table2cell(torder(torder.side==1,:))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
    case 'һ������ͨ'
        torder.stockcode=cellfun(@(x) ['''' x],torder.stockcode,'un',0);
        torder=torder(:,{'stockcode','name','tradeqty'});        
        torder.price=repmat({'��һ'},size(torder,1),1);
        torder.price(torder.tradeqty<0,:)={'��һ'}; %update���������˱�����
        corder=[{'����','����','����','�۸�'};table2cell(torder)];
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end  
        xlswrite(chFile,corder);
    case '�����ʹ�'
        torder=torder(:,{'stockcode','tradeqty'});  
        buyrows=torder.tradeqty>0;    
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        corder=[{'��Ч','','','','�ɷ�ȯ����','','','','','','����'};cat(2,repmat({''},sum(buyrows),4),torder.stockcode(buyrows),...
            repmat({''},sum(buyrows),5),num2cell(torder.tradeqty(buyrows)))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,corder);
        corder=[{'��Ч','','','','�ɷ�ȯ����','','','','','','����'};cat(2,repmat({''},sum(~buyrows),4),torder.stockcode(~buyrows),...
            repmat({''},sum(~buyrows),5),num2cell(torder.tradeqty(~buyrows)))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.csv'];
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
        corder=[{'֤ȯ����','ί�з���','ָ������','ָ��۸�','�۸�ģʽ','�����г��ڲ����'};table2cell(torder(buyrows,:))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'֤ȯ����','ί�з���','ָ������','ָ��۸�','�۸�ģʽ','�����г��ڲ����'};table2cell(torder(~buyrows,:))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);  
    case '��Ͷ'
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
        corder=[{'֤ȯ����','֤ȯ����','�����г�','ί�з���','�۸�����','ί�м۸�','ί������','ί�н��'};table2cell(torder(buyrows,:))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,corder);  
        corder=[{'֤ȯ����','֤ȯ����','�����г�','ί�з���','�۸�����','ί�м۸�','ί������','ί�н��'};table2cell(torder(~buyrows,:))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,corder);
    case 'Ͷ��Ӯ��'
        torder.buy=repmat({'��һ��'},size(torder,1),1);
        torder.sell=repmat({'��һ��'},size(torder,1),1);        
        torder=torder(:,{'stockcode','name','tradeqty','buy','sell'}); 
        buyrows=torder.tradeqty>0;
        torder.tradeqty(torder.tradeqty<0)=-torder.tradeqty(torder.tradeqty<0); 
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        Utilities.cell2csv(chFile,table2cell(torder(buyrows,:)));          
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.csv'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        Utilities.cell2csv(chFile,table2cell(torder(~buyrows,:)));     
    case '�н�IMS'
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
        corder=[{'�г�','��Լ����','ί�з���','Ͷ���ױ�','�۸�����','����','��ע'};table2cell(torder(buyrows,:))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'�г�','��Լ����','ί�з���','Ͷ���ױ�','�۸�����','����','��ע'};table2cell(torder(~buyrows,:))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);     
    case '�㷢PB'
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
        corder=[{'֤ȯ����','ί�з���','ָ������','ָ��۸�','�۸�ģʽ','�����г�','Ͷ������','Ͷ����־','��Ʒ���','�ʲ���Ԫ','��ϱ��'};table2cell(torder(buyrows,:))]; %������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-buy.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end       
        xlswrite(chFile,corder);
        corder=[{'֤ȯ����','ί�з���','ָ������','ָ��۸�','�۸�ģʽ','�����г�','Ͷ������','Ͷ����־','��Ʒ���','�ʲ���Ԫ','��ϱ��'};table2cell(torder(~buyrows,:))]; %��������
        chFile = ['\\192.168.1.88\Trading Share\' trader '\����ָ��\' account model '-sell.xlsx'];
        if exist(chFile,'file')
            delete(chFile)
        end     
        xlswrite(chFile,corder);  
    otherwise
        warning(['����ϵͳ''' system '''δָ���µ���ʽ��'])
end
end