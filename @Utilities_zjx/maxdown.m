function [MaxDown,nStartIndex,nEndIndex] = maxdown( dPrices )

% 输入：竖直排列的一列或多列价格（基金复权净值）序列
% 输出：第一个输出为输入序列中的最大回撤值，第二个输出为最大回撤起始序号，
%       第三个输出为最大回撤结束的序号。
%
% 参考：最大子向量和算法。例如（http://www.cnblogs.com/lienhua34/p/3703841.html）
%
% 原理：将价格序列转化为对数收益率序列，然后针对这个对数收益率序列求出它的最小
%       子向量和以及对应和最小的子向量的起始和结束位置。
% 作者：Lary
%       Lary 2016.07.28 update: 自动识别是否为收益。

%% 检查第一列是否为YYYYMMDD类型的数据。
bPrice = all(dPrices>0);
if bPrice
    dReturns = diff(log(dPrices));
else
    dReturns = dPrices;
end

%% 获取日期和资产数量
nDates = numel(dReturns(:,1));
nStocks = numel(dReturns(1,:));

%% 定义输出 
MaxDown = nan(1,nStocks);
nStartIndex = nan(1,nStocks);
nEndIndex = nan(1,nStocks);
for iStocks = 1:nStocks 

    nStartIndex_Current = 0;
    
    %% 定义中间变量MinAll跟MinHere用来追踪序列中的最小向量和
    dMinAll = 0;
    dMinHere = 0;
        for iDates = 1:nDates
            dMinHere = dMinHere + dReturns(iDates,iStocks);

            if dMinHere>=0
                dMinHere = 0;
                nStartIndex_Current = iDates+1;
            end

            if dMinHere<dMinAll
               %% 当MinHere小于MinAll时，记录最小和与对应的起始、结束位置。
                dMinAll = dMinHere;
                nStartIndex(iStocks) = nStartIndex_Current;
                nEndIndex(iStocks) = iDates + 1;
            end
        end
        %% 将最小对数收益率和转化为最大回撤
        if bPrice
            MaxDown(iStocks) = 1 - exp(dMinAll);
        else
            MaxDown(iStocks) = -dMinAll;
        end
        
        
end

end