function dSig = pos2sig(dPos)
%% pos2sig将一组持仓信号转化为用于回测的信号表
% dSig的第一列为日期或时间、第二列表示今日是否发出信号
%        第三轮表示今日交易的目标权重（或下单数量）。
%        本函数输出的第一列默认留空，请自行填充时间信息。
%
% - by Lary 2016.03.10
%

nDates = numel(dPos);
dSig = zeros(nDates,3);
Temp = double(diff([0;dPos])~=0);
dSig(:,2) = Temp;
dSig(:,3) = dPos;

end