function [dNav,dpos] = NSWtoday(dRtns,dObsArg,dEMAarg,dPercentArg,bForget)
if ~exist('dObsArg','var')
    dObsArg = 250;
end
if ~exist('dPercentArg','var')
    dPercentArg = 0.1;
end
if ~exist('dEMAarg','var')
    dEMAarg = 10;
end
if ~exist('bForget','var')
    bForget = true;
end

dRtnsEMA = TA_zjx.EMA(dRtns,dEMAarg);

dpos = zeros(size(dRtns));

nDates = size(dRtns,1);
nCodes = size(dRtns,2);
for iDate = dObsArg+1:nDates
    bGood = ~isnan(dRtns(iDate-dObsArg,:));
    nGood = sum(bGood,2);
    nTops = round(nGood*dPercentArg);
    
    if bForget
        tpRtns = dRtnsEMA(iDate,:);
    else
        tpRtns = dRtns(iDate,:);
    end
    
    tpRtns2 = dRtns(iDate-dObsArg,:);
    tpRtns(isnan(tpRtns)) = 0;
    [~,tpixRank] = sort(tpRtns);
    tpixRank(ismember(tpixRank,find(isnan(tpRtns2)))) = [];
    
    bSigLong = false(1,nCodes);
    bSigLong(tpixRank(end-nTops+1:end)) = true;
    bSigShort = false(1,nCodes);
    bSigShort(tpixRank(1:nTops)) = true;
    
    % 保留跌停的多头仓位和涨停的空头仓位
    
    if any(bSigLong|bSigShort)
        bActLong = bSigLong;
        nActLong = sum(bActLong,2);
        dpos(iDate,bActLong) = 1/max(nActLong,1)/2;

        bActShort = bSigShort;
        nActShort = sum(bActShort,2);
        dpos(iDate,bActShort) = -1/max(nActShort,1)/2;
    end
end

dRtns(isnan(dRtns)) = 0;
dposrtns = sum(dRtns.*dpos,2);
dNav = exp(cumsum(log(1+dposrtns)));

end