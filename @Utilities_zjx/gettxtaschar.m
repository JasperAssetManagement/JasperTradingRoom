function chOutput = gettxtaschar(chFile,varargin)
% 本函数用于读取txt文件。将其中的所有内容
% 读取到chOutput中。
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