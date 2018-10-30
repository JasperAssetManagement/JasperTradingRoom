function cCodes = getwindcode(cCodes)
% 将期货代码转化为wind代码。
% 
% 
% - by Lary 2016.11.30 

if isa(cCodes,'char')
    cCodes = {cCodes};
end

tFu = Utilities_zjx.getFuInfoAll2;
nCodes = numel(cCodes);
cAllCodes = cellstr(tFu.Code);
cOldCodes = cellstr(tFu.OldCode);
cExCodes = cellstr(tFu.ExchangeCode);
for iCode = 1:nCodes
    chCode = cCodes{iCode};
    tpix = strfind(chCode,'.');
    if isempty(tpix)
        try
        FuCode = regexp(chCode,'[A-Z,a-z]+','match');
        catch
            1
        end
        FuCode = FuCode{1};
        tpchExCode = cExCodes{strcmpi(cAllCodes,FuCode) | strcmpi(cOldCodes,FuCode)};
        
        YYMM = regexp(chCode,'[0-9]+','match');
        if isempty(YYMM)
            cCodes{iCode} = [FuCode '.' tpchExCode];
        else
            YYMM = YYMM{1};
            if numel(YYMM) == 4 && strcmpi(tpchExCode,'CZC') && str2double(YYMM)>1606
                YYMM = YYMM(2:end);
            end
            cCodes{iCode} = [FuCode YYMM '.' tpchExCode];
        end
    end
end

end