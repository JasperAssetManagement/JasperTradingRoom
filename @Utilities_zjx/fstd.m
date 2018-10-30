function std = fstd(dData,dFF)

if ~exist('dFF','var')
    dFF = 1;
end

nDates = size(dData,1);
tpw = (nDates:-1:1);
tpw = dFF.^tpw;
tpw = tpw./sum(tpw)*nDates/(nDates-1);

tpm = mean(dData);
std = sqrt(tpw * ((dData-repmat(tpm,nDates,1)).^2));

end