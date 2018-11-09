function [sum] = test_timer_classmethod(a, b)
%TEST_TIMER_CLASSMETHOD 此处显示有关此函数的摘要
%   此处显示详细说明
sum=a+b;
str=['date:' datestr(today(),'yyyymmdd') ' sum:' num2str(sum)]
end

