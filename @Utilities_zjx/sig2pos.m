function pos = sig2pos(sig,bSign)
% 将交易信号（1 0 0 -1 0 0 1 -1）转换为持仓信号（1 1 1 -1 -1 -1 1 -1）
% 
% 
% - by Lary 2016.03.18
%      Lary 2016.05.19 增加bSign输入

if nargin == 1
    bSign = true;
end
if bSign 
    sig = sign(sig);
end
nDates = numel(sig);
pos = zeros(size(sig));
dPos = 0;
for iDate = 1:nDates
    if sig(iDate)~=0
        dPos = sig(iDate);
    end
    pos(iDate) = dPos;
end
end