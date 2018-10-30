function output = getmaintrend(dPrices)

[~,ixH] = max(dPrices);
[~,ixL] = min(dPrices);
output = double(ixH<ixL)-double(ixH>ixL);

end