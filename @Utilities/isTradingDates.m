function [ flag ] = isTradingDates( date,market )
% �ж�data�Ƿ�Ϊ������
%   input
%       date:��������ڣ�֧����ֵ�ͺ��ַ��ͣ�yyyymmdd)
%       market:���ĸ��г��Ľ����ս��в�ѯ
%   output
%       flag:1 �ǽ����գ�0 �ǽ�����
if ~exist('date','var')
    date=today();
end
if ~isnumeric(date)
    date=datenum(date,'yyyymmdd');
end

if ~exist('market','var')
    market='SZ';
end

if Utilities.tradingdate(date,0,'market',market)==date
    flag=1;
else
    flag=0;
end
end

