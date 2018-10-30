function output = corrnan(A,MinObs)
% ���ڼ��㺬��nan�����ϵ����A�����Ƕ��У�bֻ��һ��
% - by Lary 2016.07.28
if nargin == 1
    nDates = numel(A(:,1));
    MinObs = max(0.3*nDates,100);
end
nStocks = size(A,2);
output = [];
for jStock = 1:nStocks
    B = A(:,jStock);
    output = cat(1,output,corr(A,B)');
    bBadCols = isnan(output(end,:));
    if any(bBadCols)
        ixBadCols = find(bBadCols);
        nStocks = numel(ixBadCols);
        for iStock = 1:nStocks
            tpdata = A(:,ixBadCols(iStock));
            bGood = ~isnan(tpdata) & ~isnan(B);
            if sum(bGood)>MinObs
                output(jStock,ixBadCols(iStock)) = corr(A(bGood,ixBadCols(iStock)),B(bGood));
            end
        end
    end
end

end