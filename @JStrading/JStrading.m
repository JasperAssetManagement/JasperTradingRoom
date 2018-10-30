classdef JStrading < handle
% JGTA: a class for extracting data and manage trading tools from databases.
%
% - by Lary 2017.04.18
%           2017.06.08 update: ������85���ݿ�Ĳ��ֹ��ܡ�
%           2017.07.05 update: �޸���getJasperPosition�Ĵ���


    properties
        classdir
        dbconn % 88���ݿ��޸�Ȩ��
        irdbconn % 85��ѯȨ��
        irdbadmin % 85�޸�Ȩ�ޣ����֣�
        cninfoconn % �޳����ݿ��ѯȨ��
        version = '0.0.0' % �汾��
    end
    
    methods
        
        function obj = JStrading() % ��ǰ������·�� 
            
            obj.classdir = fileparts(which('JStrading'));
            
        end
        
        function conn = get.dbconn(obj) % 88���ݿ���޸�Ȩ�޵�����
            close(obj.dbconn)
            dbase='master';
            ip='192.168.1.88';
            user='WRTrader';
            password='123.abc';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
            obj.dbconn = conn;
        end
        
        function conn = get.irdbconn(obj) % 85���ݿ�����
            close(obj.irdbconn)
            dbase='master';
            ip='jasperam.sqlserver.rds.aliyuncs.com,3433';
            user='IRUser';
            password='wR8MQehX';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
        end
        
        function conn = get.irdbadmin(obj) % 85���ݿ��޸�Ȩ������
            close(obj.irdbconn)
            dbase='master';
            ip='jasperam.sqlserver.rds.aliyuncs.com,3433';
            user='IRUser';
            password='wR8MQehX';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
        end
        
        function conn = get.cninfoconn(obj) % 89�ľ޳���������
            close(obj.cninfoconn)
            dbase='master';
%             ip='10.144.64.90';
            ip='192.168.1.89';
            user='hkjcUser';
            password='123@qwe';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
            obj.cninfoconn = conn;
        end
        
        %----------------------get���������ķָ���--------------------------
        
        function tInfo = getHoldingList(obj,chDate) % ��ȡ�ֲ��б�
            if ~exist('chDate','var') || isempty(chDate)
                chDate = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyymmdd');
            elseif isa(chDate,'double')
                chDate = datestr(chDate,'yyyymmdd');
            end
            
            conn = obj.dbconn;
            sqlstatement = ['select distinct windcode from [JasperDB].[dbo].[JasperPosition] where type like ''S'' and trade_dt = ' chDate];
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
            if ~isempty(cData)
                tpcodes = cellfun(@(x)(str2double(x(1:end-3))),cData(:,1));
                cData(:,1) = num2cell(tpcodes);
                tInfo = cell2table(cData,'VariableNames',{'code'});
            else
                tInfo = [];
            end
        end
        
        function tPosition = getJasperPosition(obj,chDate) % ��ȡ��Ʒ���ճֲ��嵥
            if ~exist('chDate','var') || isempty(chDate)
                chDate = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyymmdd');
            elseif isa(chDate,'double')
                chDate = datestr(chDate,'yyyymmdd');
            end
            
            conn = obj.dbconn;
%             sqlstatement = ['select windcode,Account,Qty from [JasperDB].[dbo].[JasperPosition] where Account = ''10'' and trade_dt = ' chDate ];
%             sqlstatement = ['select windcode,Account,Qty from [JasperDB].[dbo].[JasperPosition] where trade_dt = ' chDate ];
            sqlstatement = ['select windcode,name,Account,Qty,side from [JasperDB].[dbo].[JasperPosition] where trade_dt = ''' chDate ''' and (Account not in (SELECT distinct [FundAccount] FROM [JasperDB].[dbo].[JasperPIPEProportion]))'];
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
            
            if ~isempty(cData)
                tPosition = cell2table(cData,'VariableNames',{'windcode','name','account','qty','side'});
                bFu = cellfun(@(x)any(strcmpi(x(end-3:end),{'.CFE','.CZC','.DCE','.SHF'})),tPosition.windcode);
                tPosition.name(bFu) = tPosition.windcode(bFu);
                tPosition.qty(tPosition.side == 2) = -tPosition.qty(tPosition.side == 2);
                cData = Utilities_zjx.pivottable(table2cell(tPosition),[1 2 3],4,@sum);
                tPosition = cell2table(cData,'VariableNames',{'windcode','name','account','qty'});
            else
                tPosition = [];
            end
        end
        
        function tInfo = getTradeDetail(obj,chDate) % ��ȡ���в�Ʒ���ճɽ���¼
            if ~exist('chDate','var') || isempty(chDate)
                chDate = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyymmdd');
            elseif isa(chDate,'double')
                chDate = datestr(chDate,'yyyymmdd');
            end
            
            conn = obj.dbconn;
            sqlstatement = ['select Account,WindCode,type,Side,Price,Qty,Amt from [JasperDB].[dbo].[JasperTrade] where trade_dt = ' chDate];
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
            if ~isempty(cData)
                tInfo = cell2table(cData,'VariableNames',{'account','windcode','type','side','dealprice','dealqty','amt'});
                tInfo.amt = tInfo.dealprice.*tInfo.dealqty;
            else
                tInfo = [];
            end
        end
        
        function cData = getLatestModelList(obj) % ��ȡ���µ�ģ�͹�Ʊ��
            conn = obj.dbconn;
            
            sqlstatement = 'select Code from [JasperDB].[dbo].JasperModelInfo where Trade_dt=(select max(Trade_dt) from [JasperDB].[dbo].JasperModelInfo)';
            cData = obj.getsqlrtn(conn,sqlstatement);
            cData = Utilities_zjx.getwindstockcode(cData);
            close(conn)
        end
        
        function cData = getLatestForbiddenList(obj) % ��ȡ���µĹ�����ֹ��
            conn = obj.dbconn;
            sqlstatement = 'select WindCode from [JasperDB].[dbo].JasperForbiddenStock where account = ''0'' and issell = ''TRUE'' and (StartDt<= convert(varchar(8),GETDATE(),112) and (EndDt>convert(varchar(8),GETDATE(),112) or len(EndDt)=0))';
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
        end
        
        function cData = getLatestForbiddenList2(obj) % ��ȡ�����ƽ������Ĺ�����ֹ��
            conn = obj.dbconn;
            sqlstatement = 'select WindCode from [JasperDB].[dbo].JasperForbiddenStock where account = ''0'' and issell = ''TRUE'' and isvollimit = ''FALSE'' and (StartDt<= convert(varchar(8),GETDATE(),112) and (EndDt>convert(varchar(8),GETDATE(),112) or len(EndDt)=0))';
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
        end
        
        function tInfo = getResumeInfo(obj) % ��ȡ�ֲֹ�Ʊ���е�ͣ����Ϣ
            tResume = obj.getResumeFiling;
            tHolding = obj.getHoldingList;
            tInfo = innerjoin(tHolding,tResume);
        end
        
        function tInfo = getHoldingFiling(obj) % ��ȡ�ֲֹ�Ʊ�ص����й����б�
            chDateStart = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyy-mm-dd');
            tNews = obj.getFilingKeyword('',chDateStart);
            tHolding = obj.getHoldingList;
            tInfo = innerjoin(tHolding,tNews);
        end
        
        function tInfo = getHoldingDivNews(obj) % ��ȡ�ֲֹ�Ʊ�صķֺ���Ϣ
            tpirconn = obj.irdbconn;
            tmr = Utilities_zjx.tradingdate(today());
            getDivinfoSQL = ['select wind_code,stk_dvd_per_sh,ex_dt from windfilesync.dbo.asharedividend where ex_dt = ' datestr(tmr,'yyyymmdd')];
            cData = obj.getsqlrtn(tpirconn,getDivinfoSQL);
            close(tpirconn);
            if ~isempty(cData)
                tpcodes = cellfun(@(x)(str2double(x(1:end-3))),cData(:,1));
                cData(:,1) = num2cell(tpcodes);
                tDivInfo = cell2table(cData,'VariableNames',{'code','splitrate','exdt'});
                tHolding = obj.getHoldingList;
                tInfo = innerjoin(tDivInfo,tHolding);
            else
                tInfo = [];
            end
        end
        
        function tInfo = getAccountDetail(obj,chDate) %��ȡaccount detail��Ϣ 
            if ~exist('chDate','var') || isempty(chDate)
                chDate = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyymmdd');
            elseif isa(chDate,'double')
                chDate = datestr(chDate,'yyyymmdd');
            end
            
            conn = obj.dbconn;
            sqlstatement = ['select Trade_dt,Account,TotalAsset,TotalReturn,portfolio_universe,a1 from [JasperDB].dbo.accountdetail where trade_dt = ' chDate];
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn);
            if ~isempty(cData)
                tInfo = cell2table(cData,'VariableNames',{'trddt','id','totalasset','totalreturn','portfolio_universe','a1'});
            else
                tInfo = [];
            end
        end
        
        function tInfo = getAccountDict(obj) % ��ȡ��Ʒ�ֵ�
            conn = obj.dbconn;
            sqlstatement = ['select s_type,s_key,s_value,remark from [JasperDB].[dbo].dictionary'];
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn);
            
            if ~isempty(cData)
                tInfo = cell2table(cData,'VariableNames',{'type','id','name','remark'});
            else
                tInfo = [];
            end
        end
        
        function tInfo = getModelFiling(obj) % ��ȡģ�͹�Ʊ�صĹ�����Ϣ
            conn = obj.cninfoconn;
            
            chDateHM = [datestr(Utilities_zjx.tradingdate(today(),-1),'yyyy-mm-dd') ' 15:30'];
            
            sqlstatement = ['SELECT SECCODE,F001D,F002V from JCDB.dbo.INFO3015 where F001D > ''' chDateHM ''' and (seccode like ''_0____.sz'' or seccode like ''60____.SH'')'];
    
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn);
            
            if ~isempty(cData)
                tpcodes = cellfun(@(x)(str2double(x(1:end-3))),cData(:,1));
                cData(:,1) = num2cell(tpcodes);
                tInfo = cell2table(cData,'VariableNames',{'code','time','title'});
                cModelList = obj.getLatestModelList;
                dcodes = cellfun(@(x)str2double(x(1:6)),cModelList);
                tCodes = cell2table(num2cell(dcodes),'VariableNames',{'code'});
                tInfo = innerjoin(tCodes,tInfo);
            else
                tInfo = [];
            end
        end
        
        function tInfo = getFilingKeyword(obj,chKeyword,chDateStart) % ��ȡ�ؼ��ֹ���
            if ~exist('chKeyword','var')% || isempty(chKeyword)
                chKeyword = '�б�';
            end
            if ~exist('chDateStart','var') || isempty(chDateStart)
                chDateStart = datestr(Utilities_zjx.tradingdate(today(),-20),'yyyy-mm-dd');
            elseif isa(chDateStart,'double')
                chDateStart = datestr(chDateStart,'yyyy-mm-dd');
            end
            conn = obj.cninfoconn;
            
            sqlstatement = ['SELECT SECCODE,F001D,F002V from JCDB.dbo.INFO3015 where F001D > ''' chDateStart ''' and F002V like ''%' chKeyword '%'' and (seccode like ''002___.sz'' or seccode like ''000___.sz'' or seccode like ''300___.sz'' or seccode like ''60____.SH'')'];
    
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn);
            
            if ~isempty(cData)
                tpcodes = cellfun(@(x)(str2double(x(1:end-3))),cData(:,1));
                cData(:,1) = num2cell(tpcodes);
                tInfo = cell2table(cData,'VariableNames',{'code','time','title'});
            else
                tInfo = [];
            end
        end
        
        function tInfo = getResumeFiling(obj,chDateStart) % ��ȡ���ƹ��� 
            if ~exist('chDateStart','var') || isempty(chDateStart)
                chDateStart = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyy-mm-dd');
            elseif isa(chDateStart,'double')
                chDateStart = datestr(chDateStart,'yyyy-mm-dd');
            end
            chDateStart = [chDateStart ' 15:00'];
            
            conn = obj.cninfoconn;
            
            sqlstatement = ['SELECT SECCODE,F001D,F002V from JCDB.dbo.INFO3015 where F001D > ''' chDateStart ''' and F002V like ''%����%'' and F002V not like ''%���ڸ���%'' and F002V not like ''%����ͣ��%'' and F002V not like ''%������%'' and (seccode like ''00____.sz'' or seccode like ''300___.sz'' or seccode like ''60____.SH'')'];
    
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn);
            
            if ~isempty(cData)
                tpcodes = cellfun(@(x)(str2double(x(1:end-3))),cData(:,1));
                cData(:,1) = num2cell(tpcodes);
                tInfo = cell2table(cData,'VariableNames',{'code','time','title'});
            else
                tInfo = [];
            end
        end
        
        function getHoldingCapStructre(obj,chDate) % ��ȡ�ֲ���ֵ�ṹ
            
            if ~exist('chDate','var') || isempty(chDate)
                chDate = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyymmdd');
            elseif isa(chDate,'double')
                chDate = datestr(chDate,'yyyymmdd');
            end
            tPosition = getJasperPosition(obj,chDate);
            tPosition = tPosition(strcmpi(tPosition.account,'05'),:);
            cPos = table2cell(tPosition(:,{'windcode','qty'}));
            cStocks = Utilities_zjx.pivottable(cPos,1,2,@sum);
            tStocks = cell2table(cStocks,'VariableNames',{'windcode','qty'});
            bkt = JSbkt;
            jsd = JSdata;
            cCodes = Utilities_zjx.getwindstockcode(jsd.rq.stockcode);
            dCapsPct3 = getcappct(bkt);
            tixRQ = cell2table([cCodes,num2cell(1:numel(cCodes))'],'VariableNames',{'windcode','ixr'});
            tpt = innerjoin(tixRQ,tStocks);
            tpt.close = jsd.sq.close(end,tpt.ixr)';
            tpt.weight = (tpt.qty.*tpt.close)/sum(tpt.qty.*tpt.close);
            tpdw = zeros(1,numel(cCodes));
            tpdw(tpt.ixr) = tpt.weight;
            
            aaa = dCapsPct3(end,:);
            nGs = 10;
            dCapGroupWeights2 = [];
            for iG = 1:nGs
                tpb = aaa>(iG-1)/nGs & aaa<=iG/nGs;
                tpcappp = aaa;
                tpcappp(~tpb) = 0;
                tpw = tpcappp./sum(tpcappp);
                dCapGroupWeights2 = cat(1,dCapGroupWeights2,tpw);
            end
            dCGW2 = dCapGroupWeights2';
            
            bar(tpdw*double(logical(dCGW2)))
        end
        
    end
    
    methods(Static)
        
        function tInfo = getproductinfo() % ����ά��һ����Ʒ������Ϣ�ֵ䣬�����Ժ��Ϊ��88���ݿ�ֱ�ӻ�ȡ
            
            cInfo = {'name','id','margintype','isfc','futures','futset','hstock','fcremark','tradeplatform';
                '�������о���',1,'2_1',0,0,0,0,'','hr';
                '��������ƽ��',15,'2_1',0,0,0,0,'','hr';
                'ƽ���ض�����',37,'1_2',0,1,0,0,'','o32';
                '������Զ��ȡ',73,'1_1',0,0,0,1,'','xt';
                '�����ʱ�ƽ��',45,'1_1',0,0,0,0,'','xt';
                'һ��ƽ��1��',6,'2_4',1,0,0,0,'����1��','fc';
                'һ����ȡ2��',38,'2_4',1,0,0,0,'��ȡ2��','fc';
                'һ����ȡ3��',72,'2_4',1,0,0,0,'��ȡ3��','fc';
                'һ�������ȡ',68,'2_4',1,0,0,0,'��ӯ����','fc';
%                 'һ�������ȡ',68,'2_4',1,0,0,0,'��������','fc';
                'һ�������ײ�',10,'2_4',1,0,0,0,'��ӯ����','fc';
                'һ����ȡ',7,'2_4',1,0,0,0,'��ӯ��ȡ','fc';
                'һ�������1��',83,'2_4',1,0,0,0,'�����1��','fc'};
            
            tInfo = cell2table(cInfo(2:end,:),'VariableNames',cInfo(1,:));
            tInfo.id = cellstr(num2str(tInfo.id,'%02d'));
            tInfo = sortrows(tInfo,{'id'});
        end
        
        function tInfo = getforbidinfo() % ��ֹ�����Ĳ�Ʒ��Ϣ���Ժ�Ҫ���ϵ���Ʒ�ֵ��
            cInfo = {'id','tradeplatform','trader'
                '01','hr','Lary';
                '06','fc','Lary';
                '15','hr','Lary';
                '37','o32','Lary';
                '38','fc','Lary';
                '45','xt','Lary';
                '68','fc','Lary';
                '72','fc','Lary';
                '73','xt','Lary';
                '04','xt','Anty';
                '14','xt','Anty';
                '20','xt','Anty';
                '48','o32','Anty';
                '51','xt','Anty';
                '52','xt','Anty';
                '55','ims','Anty';
                '62','o32','Anty';
                '12','xt','Harold';
                '17','xt','Harold';
                '47','xt','Harold';
                '64A','xt','Harold';
                '64B','xt','Harold';
                '36','o32','Harold';
                '42','o32','Harold';
                '80','xt','Harold';
                '13','o32','Neo';
                '07','fc','Neo';
                '58','xt','Neo';
                '79','xt','Neo';
                '05','unknown','Tui';
                '81','unknown','Tui';
                };
            tInfo = cell2table(cInfo(2:end,:),'VariableNames',cInfo(1,:));
%             tInfo.id = cellstr(num2str(tInfo.id,'%02d'));
            tInfo = sortrows(tInfo,{'id'});
        end
        
        function cData = getsqlrtn(conn,sqlstate) % ��ȡSQL���ķ��ؽ����
            curs = exec(conn,sqlstate);
            if isstruct(curs)
                error(['���ݿ����ӳ���',curs.Message]);
            else
                curs = fetch(curs);
                cData = curs.Data;
                if strcmp(cData,'No Data')
                    cData={};
                    warning('No return data')
                end
            end
            % close(conn)
            % ���ڱ����������ڶ���Ƕ����ʹ�ã��ڴ˴��ر�conn���ܵ������⡣
        end
        
        tOut = checkSettleData(chDate) % �ֲּ�¼�ͳɽ���¼�����
        
        bSuccess = dailysettlement() % �̺��ļ�����������ֲ֡����콻�׺ͽ���ֲ���֤����׼ȷ�ԡ�
        
        [tAdjustment,tInfo] = holdingstopadj(dToday) % �ֲֹ�Ʊ��ͣ����������
        
        genForbidOrder() % ���ɸ��˻���ģ�ͼ���ֹ��������
        
        makesellorders(chFile,tOrders) % ��������������
        
        makebuyorders(chFile,tOrders) % ���������򵥡�
        
        chOutput = weeklyinfo() % ÿ���г������
        
        insertOtherOrder(input)
        
        updateOtherPosition()
    end
end