function chOutput = gettxtaschar(chFile,varargin)
% ���������ڶ�ȡtxt�ļ��������е���������
% ��ȡ��chOutput�С�
% - by Lary 2016.02.29
chOutput = [];
if ~isempty(varargin)
    fh = fopen(chFile,'r','n',varargin{1});
else
    fh = fopen(chFile,'r','n');
end
sTemp = fgets(fh);
while ~isa(sTemp,'double')
    chOutput = [chOutput sTemp];
    sTemp = fgets(fh);
end
fclose(fh);
end