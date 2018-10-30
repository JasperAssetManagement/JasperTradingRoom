function posout = deferpos(dpos,nDays)
% nDates = size(dpos,1);
nStocks = size(dpos,2);

posout = dpos;

for iDate = 1:nDays
    posout(1+iDate:end,:) = posout(1+iDate:end,:) + dpos(1:end-iDate,:);
end

posout = posout./repmat(max(sum(abs(posout),2),1),1,nStocks);

tpUB = max(max(abs(dpos)));

posout(posout>tpUB) = tpUB;

end