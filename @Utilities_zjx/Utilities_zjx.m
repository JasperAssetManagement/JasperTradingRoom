classdef Utilities_zjx < handle
% Utilities_zjx����Ҫ��װ��һЩ���˳��õĹ����ຯ�����Լ�����������Դ�ĺ�����
% 
% ��������ĳ�����Ϊ�˽��matlabû�а����߿⹦�ܣ����²�ͬ���߰�֮�亯�� 
% ���Ƴ�ͻ�����⡣ͨ������ཫ�Ҹ��˱�д������ĺ�������������ʹ��ʱ����ʵ
% ��������࣬Ȼ����һ�������namespace�����á�����ֱ�Ӿ�̬���á�ԭ����
% ��˵�����¶�������к�����Ӧ���Ǿ�̬������ͬʱ���ڲ�֮���������Ա������
% ����Ҳ��Ӧ���Ǿ�̬���á�
% 
% ���ӣ�
%   ʵ�������ã�  zjx = Utilities_zjx; % �����
%                 dates = zjx.tradingdate(today,-1);
%   ��̬���ã�    dates = Utilities_zjx.tradingdate(today,-1);
% 
% - by Lary 2016.06.06           contact:zeng@jinxiong.name
    
    properties
        classpath
    end
    
    methods
        function obj = Utilities_zjx() % ���캯��
            
            tpch = fileparts(which('Utilities_zjx'));
            
            tpc = regexp(tpch,'@Utilities_zjx','split');
            
            obj.classpath = tpc{1};
            
        end
    end
    
    methods(Static)
        
        %% ����Ԥ����
        [output,bMatch] = bisearch(dTime,dTimes,iGuess) % �������еĶ�������
        [dData,dMatchedDates,dMatchedIndecies] = datamatch(cData, varargin) % ���ݶ��루������
        
        %% ����
        dTradingDates = tradingdate(dToday,nLags,varargin) % ��ȡ�������б�
        bTradingDate = istradingdate(dToday) % �ж��Ƿ�Ϊ������
        dDates = get1111dates(dDate) % ��ȡ��ʷ˫11ǰ�����ա�
        [output,y,m,d] = isYMD(dYMDdata) % �ж���ֵ��yyyymmdd
        [Datenum,Year,Month,Day] = YMD2datenum(dDates) % double����������תΪdatenum
        bGood = isGoodDatenumInput(Y,M,D)
        dDates = comtradingdate(dDates)
        
        %%  ��λ�任
        dSig = pos2sig(dPos) % ��λ���ź�
        dPos = sig2pos(sig,bSign) % �źű��λ
        posout = deferpos(dpos,nDays) % �ӳ��ֲ�ʱ��
        
        %% ��Ʒ��Լ��Ϣ
        tFuInfo = getFuInfoAll2() % ��ȡ�ڻ���Լ��Ϣ by л��
        tInfo = getwindfuinfo() % ��ȡ�ڻ���Լ��Ϣ������ȫ�꽻���·�
        IFFuInfo = getIFFuInfoAll() % ��ȡ�����ڻ���Լ��Ϣ by л��
        FuInfoTable = getCFFuInfoAll() % ��ȡ��Ʒ�ڻ���Լ��Ϣ by л��
		[IFFlag,FuCode] =  isIForCF(HYCode) % �жϴ����ǽ����ڻ�������Ʒ�ڻ�
        tResult = getCFcosts(dDatenum) % ����������Լ�ɱ���
        cInfo = getspotinfo() % ��ȡ�ֻ���Ϣ����Ʒ�ֶ�Ӧ���cdb�е��ֻ��۸�ָ����룩
        tInfo = getCFZLMonth(cCode) % ����ƷƷ�ֻ�Ծ��Լ�·ݱ�
		
        %% �ز����
		output = curveanalysis(dNav,dDates,dPos,varagin) % ���߷���
        output = curveanalysis2(dNavs) % ���߷���2 �����ڶ����ֵ����
        sout = posanalysis(dpos,varargin) % �򵥵ĳֲַ�������
        sout = rtnanalysis(drtns,dDates,varargin) % �����ʰ����������ػ��ܡ�
        
        %% �ļ�IO
        data = loadjson(fname,varargin) % ��ȡjson�ļ� by Qianqian Fang
        jsonstr = getjsonstr(rootname,obj,varargin) % ��obj�����Ժ�ֵת��Ϊjson��ʽ�ַ� by Qianqian Fang
        
        %% ��´��봦��
        cCodes = getwindcode(cCodes) % ����ͨ����ת��Ϊwind����
        cCodes = getwindwsicode(cCodes) % ����ͨ����ת��Ϊwind wsi���루����֣�������ֺ�Լ����µ�wsi����ʹ�õ��Ǿ��룩
        cCodes = getvtsymbol(cCodes) % ����ͨ����ת��Ϊctp���루����ͬ��������Сд���⣩
        cCodes = getwindstockcode(cCodes) % ����λ���ֹ�Ʊ����ת��Ϊ��¹�Ʊ���롣
        
        %% ������
        std = fstd(dData,dFF) % ����ָ����Ȩ������
        
        %% ��δ����
        output = getZLHY4Cons(cCodes,dDate) % ��ȡ����������Լ4.
        imf = emd(x,nlevel) % EMD�ֽ�
        [MaxDown,nStartIndex,nEndIndex] = maxdown( dData ) % ���س�
        output = corrnan(A,B) % ���ڼ��㺬��nan�����ϵ����A�����Ƕ��У�bֻ��һ��
        output = getmaintrend(dPrices) % ��ȡ���ɷ�
        cCodes = getcurrentindexfuturecode(dToday) % ��ȡ���ڽ��׵Ĺ�ָ�ڻ���Լ����
        nDate = getifsettledate(nYear,nMonth) % �������»�ȡ��ָ�ڻ�������
        cCodes = getpastindexfuturecode(dToday) % ��ȡ�Ѿ�����Ĺ�ָ�ڻ���Լ�����б�
        cData = datadivide(dData,dDates) % datamatch�ķ������������������ݲ�ɢΪcData����
        chText = gettxtaschar(chFile,varargin) % ��ȡtxt�ļ��������ַ���
        reatimecfid(chCon)
        fh = timmingplot(dPrices,signPos,bTrans) % ��ʱ��ͼ��
        
        matrixplot(data,varargin) % CopyRight��xiezhh��л�л���
        out = pivottable(inMatrix, pivotRow, varargin) % author: zhang@zhiqiang.org
        cell2csv(filename, cellarray) % https://cn.mathworks.com/matlabcentral/fileexchange/7363-cellwrite
        varargout = csvimport( fileName, varargin ) % by Unknown
        
        %% �򵥻ز�
        [dNav,dpos] = NSW(dRtns,dObsArg,dEMAarg,dPercentArg,bForget) % �򵥵Ķ������Իز⣬ֻ��Ҫ����һ�������ʾ��󣨻��������ݣ���
        [dNav,dpos] = NSWtoday(dRtns,dObsArg,dEMAarg,dPercentArg,bForget) % �򵥵Ķ������Իز� ��ȡ���³ֲ֡�
        
        %% ָ��Ȩ��
        tInfo = getIndexWeight(chCode,chDate) % ��ȡָ��ĳ��Ȩ��
        
        %% sendmail
        [ ] = send163mail(to, subject, message, att) % ʹ��163���䷢�ʼ���
    end
    
end




