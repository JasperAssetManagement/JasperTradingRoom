function dSig = pos2sig(dPos)
%% pos2sig��һ��ֲ��ź�ת��Ϊ���ڻز���źű�
% dSig�ĵ�һ��Ϊ���ڻ�ʱ�䡢�ڶ��б�ʾ�����Ƿ񷢳��ź�
%        �����ֱ�ʾ���ս��׵�Ŀ��Ȩ�أ����µ���������
%        ����������ĵ�һ��Ĭ�����գ����������ʱ����Ϣ��
%
% - by Lary 2016.03.10
%

nDates = numel(dPos);
dSig = zeros(nDates,3);
Temp = double(diff([0;dPos])~=0);
dSig(:,2) = Temp;
dSig(:,3) = dPos;

end