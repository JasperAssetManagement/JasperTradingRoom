function [output,bMatch] = bisearch(dTime,dTimes,iGuess)
% 本函数用于返回一个值在另一个序列中的排位。dTime是一个值，dTimes是一个序列。
% output满足条件：dTimes(output)>=dTime且 dTimes(output-1)<dTime。
% iGuess表示猜测位置。如果dTimes（output）=dTime则bMatch=1否则bMatch=0。
%
% 逻辑：二元搜索，要求被搜索序列不重复且由小到大排列。
%
% - by Lary 2015.11.23
%      Lary 2015.12.28 update: 添加了对超出范围的处理。
%      Lary 2016.01.07 update: 增加了猜测位置的功能。
nRight = numel(dTimes);
nLeft = 1;
if nargin == 3
    iGuessEnd = min(nRight,iGuess+30);
    if dTimes(iGuessEnd)>=dTime
        nRight = iGuessEnd;
    end
    iGuessStart = max(nLeft,iGuess-30);
    if dTimes(iGuessEnd)<=dTime
        nLeft = iGuessStart;
    end
    nNextQuote = floor((nLeft+nRight)/2);
else
    nNextQuote = floor(nRight/2)+1;
end

if dTimes(1)==dTime
    output = 1;
    bMatch = true;
    return
elseif dTimes(1)>dTime
    output = nan;
    bMatch = false;
    return
elseif dTimes(end)==dTime
    output = numel(dTimes);
    bMatch = true;
    return
elseif dTimes(end)<dTime
    output = nan;
    bMatch = false;
    return
end


bNotDone = dTimes(nNextQuote)<dTime || dTimes(nNextQuote-1)>=dTime;
% bDone = dTimes(nNextQuote)>=dTime && dTimes(nNextQuote-1)<dTime;

while bNotDone
    if dTimes(nNextQuote)<dTime && dTimes(nNextQuote+1)>=dTime
        nNextQuote = nNextQuote + 1;
        break
    elseif dTimes(nNextQuote)<dTime
        nLeft = nNextQuote;
    else
        nRight = nNextQuote;
    end
    bNotDone = dTimes(nNextQuote)<dTime || dTimes(nNextQuote-1)>=dTime;
    if bNotDone
        nNextQuote = floor((nLeft+nRight)/2);
    end
end
if dTimes(nNextQuote) == dTime
    bMatch = true;
else
    bMatch = false;
end
output = nNextQuote;
end