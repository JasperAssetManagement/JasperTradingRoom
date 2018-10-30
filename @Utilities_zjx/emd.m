function imf = emd(x,nlevel)
% Empiricial Mode Decomposition (Hilbert-Huang Transform)
% 参考 广发EMDT（经验模态分解）策略
% EMD分解或HHT变换
% 返回值为cell类型，依次为一次IMF、二次IMF、...、最后残差
% - by Kyle
%      Lary 2016.05.17 update: 修正了spline输入中的错误。
%      Lary 2016.05.18 update: 增加了分解次数的上限
%      Lary 2016.05.26 update: 增加输入nlevel控制分解的层数。

if nargin == 1
    nlevel = 10;
end

x   = transpose(x(:));
imf = [];
nInfs = 0;
while ~ismonotonic(x) && nInfs < nlevel
    x1 = x;
%     sd = Inf;
    while ~isimf(x1) %|| (sd > 0.1)
        s1 = getspline(x1);         % 极大值点样条曲线
        s2 = -getspline(-x1);       % 极小值点样条曲线
        x2 = x1-(s1+s2)/2;
       
%         sd = sum((x1-x2).^2)/sum(x1.^2);
%         figure(2)
%         plot(x1)
%         hold on
%         plot(s1)
%         plot(s2)
%         hold off

        x1 = x2;
    end
   
    imf{end+1} = x1;
    x          = x-x1;
    nInfs = nInfs + 1;
end
imf{end+1} = x;
end

% 是否单调
function u = ismonotonic(x)
u1 = length(findpeaks(x)) * length(findpeaks(-x));
if u1 > 0
    u = 0;
else
    u = 1;
end

% u = isempty(length(findpeaks(x))) && isempty(length(findpeaks(-x)));

end

% 是否IMF分量
function u = isimf(x)
N  = length(x);
u1 = sum(x(1:N-1).*x(2:N) < 0);                     % 过零点的个数
% if u1~=0
u2 = length(findpeaks(x))+length(findpeaks(-x));    % 极值点的个数
if abs(u1-u2) > 1
    u = 0;
else
    u = 1;
end
% else
%     u = u1;
% end
end
% 据极大值点构造样条曲线
function s = getspline(x)
N = length(x);
p = findpeaks(x);
if numel(p) == 1
    dAdj = x(p)-((N-p+1)*x(1)+p*x(end))/(N+1);
    s = spline([1 N+1],[x(1) x(end)] + dAdj,1:N);
else
    s = spline([1 p N+1],[x(1) x(p) x(end)],1:N);
end
end

% 频谱分析
function [Y, f] = FFTAnalysis(y, Ts)
Fs = 1/Ts;
L = length(y);
NFFT = 2^nextpow2(L);
y = y - mean(y);
Y = fft(y, NFFT)/L;
Y = 2*abs(Y(1:NFFT/2+1));
f = Fs/2*linspace(0, 1, NFFT/2+1);
end

% Hilbert分析
function [yenvelope, yf, yh, yangle] = HilbertAnalysis(y, Ts)
yh = hilbert(y);
yenvelope = abs(yh);                % 包络
yangle = unwrap(angle(yh));         % 相位
yf = diff(yangle)/2/pi/Ts;          % 瞬时频率
end

function n = findpeaks(x)
% Find peaks. 找极大值点，返回对应极大值点的坐标
n    = find(diff(diff(x) > 0) < 0); % 相当于找二阶导小于0的点
u    = find(x(n+1) > x(n));
n(u) = n(u)+1;                      % 加1才真正对应极大值点
end