function fh = timmingplot(dPrices,signPos,bTrans)
% ���ڻ�����գ����̣�ͼ��
% ���룺   dPricesΪdouble���͵�nDates*1�����̼ۣ���IndexData����
%              signPosΪ��С��dPrices����dPrices.close��һ���Ĳ�λ��
%              ������ʾ���࣬����ʾ���գ�0��ʾ��ȷ����
% �����   ����ͼ�εľ����
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

%% �������ź�
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
    title([index.name '��ʱ����'])
    grid on;
end

if nargout~=0
    fh = a;
end

end