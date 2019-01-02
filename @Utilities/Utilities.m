classdef Utilities < handle
    
    properties 
        
    end 
    
    methods
        
    end
    
    methods (Static)
        % 交易基础数据初始化
        datesOut = tradingdate(dToday,dSteps,varargin); %获取交易日           
        initTradingDates(dStartY,dEndY); %初始化交易日,可选择更新特定年份的交易日
        insert_trade_dates_2_80db(); %将tradingdates.mat的内容写入到jtder.public.trade_dates的数据库
        flag = isTradingDates(date,market); %判断当前日是否是交易日
        cnts = calDateDiff(startDate,endDate,varargin); %计算日期间隔
        initSecurityInfo; %初始化各证券信息
        
        % 文件操作函数
        cell2csv(fileName,cellArray,separator,excelYear,decimal); %把cell array写入一个csv文件
        varargout = csvimport( fileName, varargin ); %导入csv文件
        data = excelimport(filename,sheet,firstrow,lastrow, varargin); %导入excel文件
        data = xml2struct(file); %导入xml文件
         
        %数据库操作函数
        cData = getsqlrtn(conn,sql); %从数据库查询并获取返回数据
        execsql(conn,sql);           %执行sql语句
        [insertMask, returnedKeys] = upsert(conn,tableName,fieldNames,keyFields,data, varargin); %inserts new and updates old data to a database table
        
        %功能函数
        sendMail(to, subject, message); %发送邮件，第一次使用需初始化邮箱/密码信息
        cCode = getStockWindCode(cInitCodes,cType); %获取wind的股票代码.SH/.SZ
        
    end
    
end