function cCodes = getwindstockcode(cCodes)

if isa(cCodes,'double')
    cCodes = cellstr(num2str(cCodes,'%06d'));
end

tpd = str2double(cCodes);
bSZ = tpd<600000;
bSH = tpd>=600000;
bBad = isnan(tpd); % T00018是上交所股票

tpc = cell(size(cCodes));
tpc(bSZ) = repmat({'.SZ'},sum(bSZ),1);
tpc(bSH | bBad) = repmat({'.SH'},sum(bSH | bBad),1);
cCodes = cellfun(@(x,y)([x y]),cCodes,tpc,'UniformOutput',false);

end