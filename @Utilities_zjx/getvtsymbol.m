function cCodes = getvtsymbol(cCodes)
if nargin == 0
    fprintf('getvtsymbol: û���ṩ���룬���Ի�ȡ���ش��������������Լ�б�\n')
    gta = GTADB;
    tZLHY = gta.getDailyZLHYList;
    cCodes = tZLHY.ConCode;
end

if isa(cCodes,'char')
    cCodes = {cCodes};
end

tFu = Utilities_zjx.getFuInfoAll2;
nCodes = numel(cCodes);
cAllCodes = cellstr(tFu.Code);
cExCodes = cellstr(tFu.ExchangeCode);
for iCode = 1:nCodes
    chCode = cCodes{iCode};
    FuCode = regexp(chCode,'[A-Z,a-z]+','match');
    FuCode = FuCode{1};
    if any(strcmpi({'CZC';'CFE'},cExCodes(strcmpi(cAllCodes,FuCode))))
        cCodes{iCode} = upper(cCodes{iCode});
    else
        cCodes{iCode} = lower(cCodes{iCode});
    end
end

end