classdef Utilities < handle
    
    properties 
        
    end 
    
    methods
        
    end
    
    methods (Static)
        % ���׻������ݳ�ʼ��
        datesOut = tradingdate(dToday,dSteps,varargin); %��ȡ������           
        initTradingDates(dStartY,dEndY); %��ʼ��������,��ѡ������ض���ݵĽ�����
        insert_trade_dates_2_80db(); %��tradingdates.mat������д�뵽jtder.public.trade_dates�����ݿ�
        flag = isTradingDates(date,market); %�жϵ�ǰ���Ƿ��ǽ�����
        cnts = calDateDiff(startDate,endDate,varargin); %�������ڼ��
        initSecurityInfo; %��ʼ����֤ȯ��Ϣ
        
        % �ļ���������
        cell2csv(fileName,cellArray,separator,excelYear,decimal); %��cell arrayд��һ��csv�ļ�
        varargout = csvimport( fileName, varargin ); %����csv�ļ�
        data = excelimport(filename,sheet,firstrow,lastrow, varargin); %����excel�ļ�
        data = xml2struct(file); %����xml�ļ�
         
        %���ݿ��������
        cData = getsqlrtn(conn,sql); %�����ݿ��ѯ����ȡ��������
        execsql(conn,sql);           %ִ��sql���
        [insertMask, returnedKeys] = upsert(conn,tableName,fieldNames,keyFields,data, varargin); %inserts new and updates old data to a database table
        
        %���ܺ���
        sendMail(to, subject, message); %�����ʼ�����һ��ʹ�����ʼ������/������Ϣ
        cCode = getStockWindCode(cInitCodes,cType); %��ȡwind�Ĺ�Ʊ����.SH/.SZ
        
    end
    
end