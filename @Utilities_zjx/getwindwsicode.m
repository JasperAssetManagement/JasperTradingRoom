function cCodes = getwindwsicode(cCodes)
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
        FuCode = regexp(chCode,'[A-Z,a-z]+','match');
        FuCode = FuCode{1};
        tpchExCode = cExCodes{strcmpi(cAllCodes,FuCode) | strcmpi(cOldCodes,FuCode)};
        
        YYMM = regexp(chCode,'[0-9]+','match');
        if isempty(YYMM)
            cCodes{iCode} = [FuCode '.' tpchExCode];
        else
            YYMM = YYMM{1};
            if numel(YYMM) == 4 && strcmpi(tpchExCode,'CZC')
                YYMM = YYMM(2:end);
            end
            cCodes{iCode} = [FuCode YYMM '.' tpchExCode];
        end
    end
end

end