function [sum] = test_timer_classmethod(a, b)
%TEST_TIMER_CLASSMETHOD �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
sum=a+b;
str=['date:' datestr(today(),'yyyymmdd') ' sum:' num2str(sum)]
end

