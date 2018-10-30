classdef Utilities_zjx < handle
% Utilities_zjx类主要封装了一些本人常用的工具类函数。以及部分其他来源的函数。
% 
% 设计这个类的初衷是为了解决matlab没有包或者库功能，导致不同工具包之间函数 
% 名称冲突的问题。通过这个类将我个人编写或整理的函数整合起来，使用时可以实
% 例化这个类，然后赋予一个别称起到namespace的作用。或者直接静态调用。原则上
% 来说本类下定义的所有函数都应该是静态函数，同时类内部之间对其他成员函数的
% 调用也都应该是静态调用。
% 
% 例子：
%   实例化调用：  zjx = Utilities_zjx; % 载入包
%                 dates = zjx.tradingdate(today,-1);
%   静态调用：    dates = Utilities_zjx.tradingdate(today,-1);
% 
% - by Lary 2016.06.06           contact:zeng@jinxiong.name
    
    properties
        classpath
    end
    
    methods
        function obj = Utilities_zjx() % 构造函数
            
            tpch = fileparts(which('Utilities_zjx'));
            
            tpc = regexp(tpch,'@Utilities_zjx','split');
            
            obj.classpath = tpc{1};
            
        end
    end
    
    methods(Static)
        
        %% 数据预处理
        [output,bMatch] = bisearch(dTime,dTimes,iGuess) % 递增序列的二叉搜索
        [dData,dMatchedDates,dMatchedIndecies] = datamatch(cData, varargin) % 数据对齐（交并）
        
        %% 日期
        dTradingDates = tradingdate(dToday,nLags,varargin) % 获取交易日列表
        bTradingDate = istradingdate(dToday) % 判断是否为交易日
        dDates = get1111dates(dDate) % 获取历史双11前后交易日。
        [output,y,m,d] = isYMD(dYMDdata) % 判断数值型yyyymmdd
        [Datenum,Year,Month,Day] = YMD2datenum(dDates) % double类型年月日转为datenum
        bGood = isGoodDatenumInput(Y,M,D)
        dDates = comtradingdate(dDates)
        
        %%  仓位变换
        dSig = pos2sig(dPos) % 仓位变信号
        dPos = sig2pos(sig,bSign) % 信号变仓位
        posout = deferpos(dpos,nDays) % 延长持仓时间
        
        %% 商品合约信息
        tFuInfo = getFuInfoAll2() % 获取期货合约信息 by 谢亚
        tInfo = getwindfuinfo() % 获取期货合约信息，包含全年交割月份
        IFFuInfo = getIFFuInfoAll() % 获取金融期货合约信息 by 谢亚
        FuInfoTable = getCFFuInfoAll() % 获取商品期货合约信息 by 谢亚
		[IFFlag,FuCode] =  isIForCF(HYCode) % 判断代码是金融期货还是商品期货
        tResult = getCFcosts(dDatenum) % 生成主力合约成本表
        cInfo = getspotinfo() % 获取现货信息（各品种对应万德cdb中的现货价格指标代码）
        tInfo = getCFZLMonth(cCode) % 各商品品种活跃合约月份表
		
        %% 回测相关
		output = curveanalysis(dNav,dDates,dPos,varagin) % 曲线分析
        output = curveanalysis2(dNavs) % 曲线分析2 适用于多个净值序列
        sout = posanalysis(dpos,varargin) % 简单的持仓分析函数
        sout = rtnanalysis(drtns,dDates,varargin) % 收益率按季节性因素汇总。
        
        %% 文件IO
        data = loadjson(fname,varargin) % 读取json文件 by Qianqian Fang
        jsonstr = getjsonstr(rootname,obj,varargin) % 将obj的属性和值转化为json格式字符 by Qianqian Fang
        
        %% 万德代码处理
        cCodes = getwindcode(cCodes) % 将普通代码转化为wind代码
        cCodes = getwindwsicode(cCodes) % 将普通代码转化为wind wsi代码（对于郑商所部分合约，万德的wsi代码使用的是旧码）
        cCodes = getvtsymbol(cCodes) % 将普通代码转化为ctp代码（处理不同交易所大小写问题）
        cCodes = getwindstockcode(cCodes) % 将六位数字股票代码转化为万德股票代码。
        
        %% 波动率
        std = fstd(dData,dFF) % 计算指数加权波动率
        
        %% 尚未归类
        output = getZLHY4Cons(cCodes,dDate) % 获取当日主力合约4.
        imf = emd(x,nlevel) % EMD分解
        [MaxDown,nStartIndex,nEndIndex] = maxdown( dData ) % 最大回撤
        output = corrnan(A,B) % 用于计算含有nan的相关系数。A可以是多列，b只能一列
        output = getmaintrend(dPrices) % 获取主成分
        cCodes = getcurrentindexfuturecode(dToday) % 获取正在交易的股指期货合约代码
        nDate = getifsettledate(nYear,nMonth) % 给定年月获取股指期货交割日
        cCodes = getpastindexfuturecode(dToday) % 获取已经交割的股指期货合约代码列表
        cData = datadivide(dData,dDates) % datamatch的反函数，将对齐后的数据拆散为cData类型
        chText = gettxtaschar(chFile,varargin) % 读取txt文件，返回字符串
        reatimecfid(chCon)
        fh = timmingplot(dPrices,signPos,bTrans) % 择时画图。
        
        matrixplot(data,varargin) % CopyRight：xiezhh（谢中华）
        out = pivottable(inMatrix, pivotRow, varargin) % author: zhang@zhiqiang.org
        cell2csv(filename, cellarray) % https://cn.mathworks.com/matlabcentral/fileexchange/7363-cellwrite
        varargout = csvimport( fileName, varargin ) % by Unknown
        
        %% 简单回测
        [dNav,dpos] = NSW(dRtns,dObsArg,dEMAarg,dPercentArg,bForget) % 简单的动量策略回测，只需要输入一个收益率矩阵（或其他数据）。
        [dNav,dpos] = NSWtoday(dRtns,dObsArg,dEMAarg,dPercentArg,bForget) % 简单的动量策略回测 获取最新持仓。
        
        %% 指数权重
        tInfo = getIndexWeight(chCode,chDate) % 获取指数某日权重
        
        %% sendmail
        [ ] = send163mail(to, subject, message, att) % 使用163邮箱发邮件。
    end
    
end




