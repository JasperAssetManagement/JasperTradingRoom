function fh = timmingplot(dPrices,signPos,bTrans)
% 用于画出多空（红绿）图。
% 输入：   dPrices为double类型的nDates*1个收盘价（或IndexData对象）
%              signPos为大小与dPrices（或dPrices.close）一样的仓位表
%              （正表示看多，负表示看空，0表示不确定）
% 输出：   所画图形的句柄。
% - by Lary 2016.03.17
% 

if nargin==2
    bTrans = true;
elseif nargin<2
    error('not enough inputs.\n')
end
if isa(dPrices,'IndexData')
    bObj = true;
    index = dPrices;
    dPrices = index.close;
elseif isa(dPrices,'struct')
    bObj = true;
    index = dPrices;
    dPrices = index.close;
else
    bObj = false;
end
if ~isequal(size(dPrices),size(signPos))
    error('the size of 2 inputs are different.\n')
end

nDates = numel(dPrices);
signPos = sign(signPos);

%% 处理多空信号
if bTrans
    signPos = Utilities_zjx.sig2pos(signPos);
end

tpDiff = diff(signPos);
ixTemp = find(tpDiff~=0);
ixStart = [1;ixTemp+1];
ixEnd = [ixTemp+1; nDates];
nLines = numel(ixStart);
figure()
hold on
for iLine = 1:nLines
    if signPos(ixStart(iLine))==1
        chColor = 'r';
    elseif signPos(ixStart(iLine))==-1
        chColor = 'g';
    else
        chColor = 'b';
    end
    
    plot(ixStart(iLine):ixEnd(iLine),dPrices(ixStart(iLine):ixEnd(iLine)),chColor)
    
    
end

if bObj
    a = gcf;
    a = a.Children;
    a.XLim(2) = nDates;
    iTicks = a.XTick;
    iTicks(1) = 1;
    cTickLabel = cellstr(datestr(index.dates(iTicks)','yyyy-mm-dd'));
    a.XTickLabel = cTickLabel;
    title([index.name '择时走势'])
    grid on;
end

if nargout~=0
    fh = a;
end

end