function imf = emd(x,nlevel)
% Empiricial Mode Decomposition (Hilbert-Huang Transform)
% �ο� �㷢EMDT������ģ̬�ֽ⣩����
% EMD�ֽ��HHT�任
% ����ֵΪcell���ͣ�����Ϊһ��IMF������IMF��...�����в�
% - by Kyle
%      Lary 2016.05.17 update: ������spline�����еĴ���
%      Lary 2016.05.18 update: �����˷ֽ����������
%      Lary 2016.05.26 update: ��������nlevel���Ʒֽ�Ĳ�����

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
        s1 = getspline(x1);         % ����ֵ����������
        s2 = -getspline(-x1);       % ��Сֵ����������
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

% �Ƿ񵥵�
function u = ismonotonic(x)
u1 = length(findpeaks(x)) * length(findpeaks(-x));
if u1 > 0
    u = 0;
else
    u = 1;
end

% u = isempty(length(findpeaks(x))) && isempty(length(findpeaks(-x)));

end

% �Ƿ�IMF����
function u = isimf(x)
N  = length(x);
u1 = sum(x(1:N-1).*x(2:N) < 0);                     % �����ĸ���
% if u1~=0
u2 = length(findpeaks(x))+length(findpeaks(-x));    % ��ֵ��ĸ���
if abs(u1-u2) > 1
    u = 0;
else
    u = 1;
end
% else
%     u = u1;
% end
end
% �ݼ���ֵ�㹹����������
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

% Ƶ�׷���
function [Y, f] = FFTAnalysis(y, Ts)
Fs = 1/Ts;
L = length(y);
NFFT = 2^nextpow2(L);
y = y - mean(y);
Y = fft(y, NFFT)/L;
Y = 2*abs(Y(1:NFFT/2+1));
f = Fs/2*linspace(0, 1, NFFT/2+1);
end

% Hilbert����
function [yenvelope, yf, yh, yangle] = HilbertAnalysis(y, Ts)
yh = hilbert(y);
yenvelope = abs(yh);                % ����
yangle = unwrap(angle(yh));         % ��λ
yf = diff(yangle)/2/pi/Ts;          % ˲ʱƵ��
end

function n = findpeaks(x)
% Find peaks. �Ҽ���ֵ�㣬���ض�Ӧ����ֵ�������
n    = find(diff(diff(x) > 0) < 0); % �൱���Ҷ��׵�С��0�ĵ�
u    = find(x(n+1) > x(n));
n(u) = n(u)+1;                      % ��1��������Ӧ����ֵ��
end