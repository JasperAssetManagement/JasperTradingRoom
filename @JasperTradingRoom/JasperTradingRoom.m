classdef JasperTradingRoom < handle
    
    properties 
        classdir
        db88conn %88 db connection
        dbWindconn %85 db connection 
        db90conn %85 db connection 
        pg195conn
    end 
    
    methods
        function obj = JasperTradingRoom() % 当前类所在路径             
            obj.classdir = fileparts(which('JasperTradingRoom'));            
        end   
        
        function conn = get.db88conn(obj) % 88 db connection
            close(obj.db88conn);
            dbase='JasperDB';
            ip='192.168.1.88';
            user='TraderOnly';
            password='112358.qwe';
            url=['jdbc:sqlserver://',ip,';database=',dbase];
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
            obj.db88conn = conn;
        end
        
        function conn = get.dbWindconn(obj) % aliyun db connection
            close(obj.dbWindconn);
            dbase='windfilesync';
            ip='jasperam.sqlserver.rds.aliyuncs.com:3433';
            user='IRUser';
            password='wR8MQehX';
            url=['jdbc:sqlserver://',ip,';database=',dbase];
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
            obj.dbWindconn = conn;
        end
        
        function conn = get.pg195conn(obj) % 90 db connection
            close(obj.pg195conn);
            dbase='attribution';
            ip='postgres195.inner.jasperam.com:5433';
            user='jttrade';
            password='jttrade123';
            url=['jdbc:postgresql://',ip,'/'];
            driver='org.postgresql.Driver';
            conn = database(dbase,user,password,driver,url);
            obj.pg195conn = conn;
        end
        
        function conn = get.db90conn(obj) % 90 db connection
            close(obj.db90conn);
            dbase='ZLHY';
            ip='192.168.1.90';
            user='IRUser';
            password='Password.123';
            url=['jdbc:sqlserver://',ip,';database=',dbase];
            driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
            conn = database(dbase,user,password,driver,url);
            obj.db90conn = conn;
        end
        
        function cAccT = getaccounts(obj, date, newAccT)                     
            conn=obj.pg195conn;
            sqlstr=['SELECT distinct on (product_id, sec_type) product_id,product_name,trader,commission,sec_type,institution,min_commission,root_product_id ', ...
                        'FROM "public"."product" where status=''''running'''' order by product_id,sec_type,update_time desc'];
            rowdata=Utilities.getsqlrtn(conn,sqlstr); 
            cAccT=cell2table(rowdata,'VariableNames',{'id','account_name','trader','commission','sec_type','institution','min_commission','root_account'});
            % get total capital
            conn=obj.db88conn;
            sqlstr=['SELECT [Account],isnull(TotalAsset,0) FROM [JasperDB].[dbo].[AccountDetail] where Trade_dt=''' date ''';'];
            rowdata=Utilities.getsqlrtn(conn,sqlstr);
            capT=cell2table(rowdata,'VariableNames',{'id','capital'});
            if ~isempty(newAccT)
                [ia,l]=ismember(newAccT.id,capT.id);
                if sum(ia==1)>0
                    capT.capital(l(ia==1))=capT.capital(l(ia==1))+newAccT.capital(ia==1);
                end
                if sum(ia==0)>0
                    capT=[capT;newAccT(ia==0,:)];
                end
            end
            cAccT=innerjoin(cAccT,capT,'LeftKeys','root_account','RightKeys','id');           
        end
        
        function cAccList = getzfaccounts(obj,date)    
            %获取有ZF orders的账户id
            conn = obj.db88conn;
            sqlstr = ['SELECT distinct [account] FROM [JasperDB].[dbo].[JasperZFOrders] where date=''' date ''';'];
            cAccList = Utilities.getsqlrtn(conn,sqlstr);  
        end
        
        function cTarAcc=getType0Acc(obj)
            %选出所有正在交易的账户
            conn = obj.db88conn;
            sqlstr = ['SELECT [s_key] FROM [JasperDB].[dbo].[Dictionary] ' ...
                'where s_status=''running'' and CHARINDEX(''定增'',remark)=0 and LEN(trader)>0 and s_key not in (''10'',''67'',''44'',''48''); '];
            cTarAcc = Utilities.getsqlrtn(conn,sqlstr);            
        end 
        
        function cTarAcc=getType1Acc(obj)
            %选出规模大于1500万且没有港股交易的账户 for JASON
            date=Utilities.tradingdate(today(),-1,'outputStyle','yyyymmdd');
            conn = obj.db88conn;
            sqlstr = ['SELECT [Account] FROM [JasperDB].[dbo].[AccountDetail] where Trade_dt=''' date '''and TotalAsset>15000000 ' ...
                'and Account not in (select distinct Account from JasperDB.dbo.JasperPosition where Type=''HKS'' and Trade_dt=''' date ''') ' ...
                'and Account in (select s_key from [JasperDB].[dbo].[Dictionary] where CHARINDEX(''进取'',s_value)>0 and s_key not in(''58'',''72'')) order by Account'];
            cTarAcc = Utilities.getsqlrtn(conn,sqlstr);
        end 
                
        function cTarAcc = getAccInfo(obj,acctype)
            switch acctype
                case 0
                    cTarAcc = obj.getType0Acc;
                case 1
                    cTarAcc = obj.getType1Acc;
                case 3
                    cTarAcc = {'07';'64';'80'}; %做ST的账户
                case 4
                    cTarAcc = {'5B'}; %做ST的账户
                otherwise
                    cTarAcc = obj.getType0Acc;
            end
        end
        
    end
    
    methods (Static)        
        importZFOrders(s_date);          %导入ZF成交单
        importInstruction(s_date);       %导入ZF指令和指令明细
        importFileOrders(dtype,s_date);  %导入以excel形式发送的成交指令
        importOtherOrders(varargin);    %通过直接输入的形式导入指令
                
        genZFOrders(date,varargin);      %生成每日交易的成交单
        genOtherPosition(s_date);        %生成每日基本面交易的目标持仓
        makeorderfile(torder,account,trader,system,model); % 根据交易系统的格式生成成交清单
        genBoothbayPosition(date, accId);       %生成每日的boothbay position
        
        insertInstruction2DB(tins,torder);     %把指令明细插入到数据库中
        deleteInstruction(acctype, varargin);  %由于要修改指令，提供删除指令的功能        
        
        copyLiquidFiles();               %复制收盘后文件到指定目录        
        weeklyMarketInfo();              %每周市场数据统计           
     
        calVwapTradingPnlOfzfModel(timezone,startDate,endDate);      %计算ZF模型每日换仓的
        calHksReturn(date);                  %计算Jason的港股的pnl
        calAShareReturn(date,modelname);     %计算modelname的A股的pnl  
        calDailyTradeEffciency(date);         %计算公司层面的交易effciency
    end
    
end