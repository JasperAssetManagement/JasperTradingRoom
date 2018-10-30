function [output,bMatch] = bisearch(dTime,dTimes,iGuess)
% ���������ڷ���һ��ֵ����һ�������е���λ��dTime��һ��ֵ��dTimes��һ�����С�
% output����������dTimes(output)>=dTime�� dTimes(output-1)<dTime��
% iGuess��ʾ�²�λ�á����dTimes��output��=dTime��bMatch=1����bMatch=0��
%
% �߼�����Ԫ������Ҫ���������в��ظ�����С�������С�
%
% - by Lary 2015.11.23
%      Lary 2015.12.28 update: ����˶Գ�����Χ�Ĵ���
%      Lary 2016.01.07 update: �����˲²�λ�õĹ��ܡ�
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