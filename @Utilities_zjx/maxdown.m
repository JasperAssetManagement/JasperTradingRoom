function [MaxDown,nStartIndex,nEndIndex] = maxdown( dPrices )

% ���룺��ֱ���е�һ�л���м۸񣨻���Ȩ��ֵ������
% �������һ�����Ϊ���������е����س�ֵ���ڶ������Ϊ���س���ʼ��ţ�
%       ���������Ϊ���س���������š�
%
% �ο���������������㷨�����磨http://www.cnblogs.com/lienhua34/p/3703841.html��
%
% ԭ�����۸�����ת��Ϊ�������������У�Ȼ�������������������������������С
%       ���������Լ���Ӧ����С������������ʼ�ͽ���λ�á�
% ���ߣ�Lary
%       Lary 2016.07.28 update: �Զ�ʶ���Ƿ�Ϊ���档

%% ����һ���Ƿ�ΪYYYYMMDD���͵����ݡ�
bPrice = all(dPrices>0);
if bPrice
    dReturns = diff(log(dPrices));
else
    dReturns = dPrices;
end

%% ��ȡ���ں��ʲ�����
nDates = numel(dReturns(:,1));
nStocks = numel(dReturns(1,:));

%% ������� 
MaxDown = nan(1,nStocks);
nStartIndex = nan(1,nStocks);
nEndIndex = nan(1,nStocks);
for iStocks = 1:nStocks 

    nStartIndex_Current = 0;
    
    %% �����м����MinAll��MinHere����׷�������е���С������
    dMinAll = 0;
    dMinHere = 0;
        for iDates = 1:nDates
            dMinHere = dMinHere + dReturns(iDates,iStocks);

            if dMinHere>=0
                dMinHere = 0;
                nStartIndex_Current = iDates+1;
            end

            if dMinHere<dMinAll
               %% ��MinHereС��MinAllʱ����¼��С�����Ӧ����ʼ������λ�á�
                dMinAll = dMinHere;
                nStartIndex(iStocks) = nStartIndex_Current;
                nEndIndex(iStocks) = iDates + 1;
            end
        end
        %% ����С���������ʺ�ת��Ϊ���س�
        if bPrice
            MaxDown(iStocks) = 1 - exp(dMinAll);
        else
            MaxDown(iStocks) = -dMinAll;
        end
        
        
end

end