function pos = sig2pos(sig,bSign)
% �������źţ�1 0 0 -1 0 0 1 -1��ת��Ϊ�ֲ��źţ�1 1 1 -1 -1 -1 1 -1��
% 
% 
% - by Lary 2016.03.18
%      Lary 2016.05.19 ����bSign����

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