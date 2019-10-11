classdef JasperTradingRoom < handle
    
    properties 
        classdir
        db88conn %88 db connection
        dbWindconn %85 db connection 
        db90conn %85 db connection 
        pg195conn
    end 
    
    methods
        function obj = JasperTradingRoom() % ��ǰ������·��             
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
            %��ȡ��ZF orders���˻�id
            conn = obj.db88conn;
            sqlstr = ['SELECT distinct [account] FROM [JasperDB].[dbo].[JasperZFOrders] where date=''' date ''';'];
            cAccList = Utilities.getsqlrtn(conn,sqlstr);  
        end
        
        function cTarAcc=getType0Acc(obj)
            %ѡ���������ڽ��׵��˻�
            conn = obj.db88conn;
            sqlstr = ['SELECT [s_key] FROM [JasperDB].[dbo].[Dictionary] ' ...
                'where s_status=''running'' and CHARINDEX(''����'',remark)=0 and LEN(trader)>0 and s_key not in (''10'',''67'',''44'',''48''); '];
            cTarAcc = Utilities.getsqlrtn(conn,sqlstr);            
        end 
        
        function cTarAcc=getType1Acc(obj)
            %ѡ����ģ����1500����û�и۹ɽ��׵��˻� for JASON
            date=Utilities.tradingdate(today(),-1,'outputStyle','yyyymmdd');
            conn = obj.db88conn;
            sqlstr = ['SELECT [Account] FROM [JasperDB].[dbo].[AccountDetail] where Trade_dt=''' date '''and TotalAsset>15000000 ' ...
                'and Account not in (select distinct Account from JasperDB.dbo.JasperPosition where Type=''HKS'' and Trade_dt=''' date ''') ' ...
                'and Account in (select s_key from [JasperDB].[dbo].[Dictionary] where CHARINDEX(''��ȡ'',s_value)>0 and s_key not in(''58'',''72'')) order by Account'];
            cTarAcc = Utilities.getsqlrtn(conn,sqlstr);
        end 
                
        function cTarAcc = getAccInfo(obj,acctype)
            switch acctype
                case 0
                    cTarAcc = obj.getType0Acc;
                case 1
                    cTarAcc = obj.getType1Acc;
                case 3
                    cTarAcc = {'07';'64';'80'}; %��ST���˻�
                case 4
                    cTarAcc = {'5B'}; %��ST���˻�
                otherwise
                    cTarAcc = obj.getType0Acc;
            end
        end
        
    end
    
    methods (Static)        
        importZFOrders(s_date);          %����ZF�ɽ���
        importInstruction(s_date);       %����ZFָ���ָ����ϸ
        importFileOrders(dtype,s_date);  %������excel��ʽ���͵ĳɽ�ָ��
        importOtherOrders(varargin);    %ͨ��ֱ���������ʽ����ָ��
                
        genZFOrders(date,varargin);      %����ÿ�ս��׵ĳɽ���
        genOtherPosition(s_date);        %����ÿ�ջ����潻�׵�Ŀ��ֲ�
        makeorderfile(torder,account,trader,system,model); % ���ݽ���ϵͳ�ĸ�ʽ���ɳɽ��嵥
        genBoothbayPosition(date, accId);       %����ÿ�յ�boothbay position
        
        insertInstruction2DB(tins,torder);     %��ָ����ϸ���뵽���ݿ���
        deleteInstruction(acctype, varargin);  %����Ҫ�޸�ָ��ṩɾ��ָ��Ĺ���        
        
        copyLiquidFiles();               %�������̺��ļ���ָ��Ŀ¼        
        weeklyMarketInfo();              %ÿ���г�����ͳ��           
     
        calVwapTradingPnlOfzfModel(timezone,startDate,endDate);      %����ZFģ��ÿ�ջ��ֵ�
        calHksReturn(date);                  %����Jason�ĸ۹ɵ�pnl
        calAShareReturn(date,modelname);     %����modelname��A�ɵ�pnl  
        calDailyTradeEffciency(date);         %���㹫˾����Ľ���effciency
    end
    
end