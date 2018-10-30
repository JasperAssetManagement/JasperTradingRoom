classdef JStrading < handle
% JGTA: a class for extracting data and manage trading tools from databases.
%
% - by Lary 2017.04.18
%           2017.06.08 update: 整合了85数据库的部分功能。
%           2017.07.05 update: 修改了getJasperPosition的错误。


    properties
        classdir
        dbconn % 88数据库修改权限
        irdbconn % 85查询权限
        irdbadmin % 85修改权限（部分）
        cninfoconn % 巨潮数据库查询权限
        version = '0.0.0' % 版本号
    end
    
    methods
        
        function obj = JStrading() % 当前类所在路径 
            
            obj.classdir = fileparts(which('JStrading'));
            
        end
        
        function conn = get.dbconn(obj) % 88数据库带修改权限的连接
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
        
        function conn = get.irdbconn(obj) % 85数据库连接
            close(obj.irdbconn)
            dbase='master';
            ip='jasperam.sqlserver.rds.aliyuncs.com,3433';
            user='IRUser';
            password='wR8MQehX';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
        end
        
        function conn = get.irdbadmin(obj) % 85数据库修改权限连接
            close(obj.irdbconn)
            dbase='master';
            ip='jasperam.sqlserver.rds.aliyuncs.com,3433';
            user='IRUser';
            password='wR8MQehX';
            url=horzcat('jdbc:sqlserver://',ip,';database=',dbase);
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
        end
        
        function conn = get.cninfoconn(obj) % 89的巨潮数据连接
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
        
        %----------------------get方法结束的分割线--------------------------
        
        function tInfo = getHoldingList(obj,chDate) % 获取持仓列表
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
        
        function tPosition = getJasperPosition(obj,chDate) % 获取产品单日持仓清单
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
        
        function tInfo = getTradeDetail(obj,chDate) % 获取所有产品当日成交记录
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
        
        function cData = getLatestModelList(obj) % 获取最新的模型股票池
            conn = obj.dbconn;
            
            sqlstatement = 'select Code from [JasperDB].[dbo].JasperModelInfo where Trade_dt=(select max(Trade_dt) from [JasperDB].[dbo].JasperModelInfo)';
            cData = obj.getsqlrtn(conn,sqlstatement);
            cData = Utilities_zjx.getwindstockcode(cData);
            close(conn)
        end
        
        function cData = getLatestForbiddenList(obj) % 获取最新的公共禁止池
            conn = obj.dbconn;
            sqlstatement = 'select WindCode from [JasperDB].[dbo].JasperForbiddenStock where account = ''0'' and issell = ''TRUE'' and (StartDt<= convert(varchar(8),GETDATE(),112) and (EndDt>convert(varchar(8),GETDATE(),112) or len(EndDt)=0))';
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
        end
        
        function cData = getLatestForbiddenList2(obj) % 获取不限制交易量的公共禁止池
            conn = obj.dbconn;
            sqlstatement = 'select WindCode from [JasperDB].[dbo].JasperForbiddenStock where account = ''0'' and issell = ''TRUE'' and isvollimit = ''FALSE'' and (StartDt<= convert(varchar(8),GETDATE(),112) and (EndDt>convert(varchar(8),GETDATE(),112) or len(EndDt)=0))';
            cData = obj.getsqlrtn(conn,sqlstatement);
            close(conn)
        end
        
        function tInfo = getResumeInfo(obj) % 获取持仓股票池中的停牌信息
            tResume = obj.getResumeFiling;
            tHolding = obj.getHoldingList;
            tInfo = innerjoin(tHolding,tResume);
        end
        
        function tInfo = getHoldingFiling(obj) % 获取持仓股票池的所有公告列表
            chDateStart = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyy-mm-dd');
            tNews = obj.getFilingKeyword('',chDateStart);
            tHolding = obj.getHoldingList;
            tInfo = innerjoin(tHolding,tNews);
        end
        
        function tInfo = getHoldingDivNews(obj) % 获取持仓股票池的分红信息
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
        
        function tInfo = getAccountDetail(obj,chDate) %获取account detail信息 
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
        
        function tInfo = getAccountDict(obj) % 获取产品字典
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
        
        function tInfo = getModelFiling(obj) % 获取模型股票池的公告信息
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
        
        function tInfo = getFilingKeyword(obj,chKeyword,chDateStart) % 获取关键字公告
            if ~exist('chKeyword','var')% || isempty(chKeyword)
                chKeyword = '中标';
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
        
        function tInfo = getResumeFiling(obj,chDateStart) % 获取复牌公告 
            if ~exist('chDateStart','var') || isempty(chDateStart)
                chDateStart = datestr(Utilities_zjx.tradingdate(today(),-1),'yyyy-mm-dd');
            elseif isa(chDateStart,'double')
                chDateStart = datestr(chDateStart,'yyyy-mm-dd');
            end
            chDateStart = [chDateStart ' 15:00'];
            
            conn = obj.cninfoconn;
            
            sqlstatement = ['SELECT SECCODE,F001D,F002V from JCDB.dbo.INFO3015 where F001D > ''' chDateStart ''' and F002V like ''%复牌%'' and F002V not like ''%延期复牌%'' and F002V not like ''%继续停牌%'' and F002V not like ''%不复牌%'' and (seccode like ''00____.sz'' or seccode like ''300___.sz'' or seccode like ''60____.SH'')'];
    
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
        
        function getHoldingCapStructre(obj,chDate) % 获取持仓市值结构
            
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
        
        function tInfo = getproductinfo() % 用来维护一个产品配置信息字典，考虑以后改为从88数据库直接获取
            
            cInfo = {'name','id','margintype','isfc','futures','futset','hstock','fcremark','tradeplatform';
                '华润信托绝对',1,'2_1',0,0,0,0,'','hr';
                '华润信托平衡',15,'2_1',0,0,0,0,'','hr';
                '平安阖鼎绝对',37,'1_2',0,1,0,0,'','o32';
                '招商智远进取',73,'1_1',0,0,0,1,'','xt';
                '银河资本平衡',45,'1_1',0,0,0,0,'','xt';
                '一创平衡1期',6,'2_4',1,0,0,0,'大岩1期','fc';
                '一创进取2号',38,'2_4',1,0,0,0,'进取2号','fc';
                '一创进取3号',72,'2_4',1,0,0,0,'进取3号','fc';
                '一创尊享进取',68,'2_4',1,0,0,0,'共盈尊享','fc';
%                 '一创尊享进取',68,'2_4',1,0,0,0,'大岩尊享','fc';
                '一创定增底层',10,'2_4',1,0,0,0,'共盈定增','fc';
                '一创进取',7,'2_4',1,0,0,0,'共盈进取','fc';
                '一创多策略1期',83,'2_4',1,0,0,0,'多策略1期','fc'};
            
            tInfo = cell2table(cInfo(2:end,:),'VariableNames',cInfo(1,:));
            tInfo.id = cellstr(num2str(tInfo.id,'%02d'));
            tInfo = sortrows(tInfo,{'id'});
        end
        
        function tInfo = getforbidinfo() % 禁止卖单的产品信息表，以后要整合到产品字典里。
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
        
        function cData = getsqlrtn(conn,sqlstate) % 获取SQL语句的返回结果。
            curs = exec(conn,sqlstate);
            if isstruct(curs)
                error(['数据库连接出错：',curs.Message]);
            else
                curs = fetch(curs);
                cData = curs.Data;
                if strcmp(cData,'No Data')
                    cData={};
                    warning('No return data')
                end
            end
            % close(conn)
            % 由于本函数可能在多重嵌套中使用，在此处关闭conn可能导致问题。
        end
        
        tOut = checkSettleData(chDate) % 持仓记录和成交记录的轧差。
        
        bSuccess = dailysettlement() % 盘后文件整理，用昨天持仓、今天交易和今天持仓验证数据准确性。
        
        [tAdjustment,tInfo] = holdingstopadj(dToday) % 持仓股票的停牌修正计算
        
        genForbidOrder() % 生成各账户非模型及禁止的卖单。
        
        makesellorders(chFile,tOrders) % 生成批量卖单。
        
        makebuyorders(chFile,tOrders) % 生成批量买单。
        
        chOutput = weeklyinfo() % 每周市场情况。
        
        insertOtherOrder(input)
        
        updateOtherPosition()
    end
end