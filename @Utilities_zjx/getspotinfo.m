function tInfo = getspotinfo()

cInfo = {'J','S5120134',0,1
        'JM','S5112240',-40,1
        'JD','S0066831',0,500
        'P','S5006009',0,1
        'ZN','S0105514',0,1
        'RM','S5005883',0,1};

tInfo = cell2table(cInfo,'VariableNames',{'Code','SpotCode','Appr','Unit'});



end