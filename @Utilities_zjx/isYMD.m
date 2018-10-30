function [output,y,m,d] = isYMD(dYMDdata)
% this function is designed to check if a vector of data is double type of
% YYYYMMDD numbers. 

d = mod(dYMDdata,100);
m = (mod(dYMDdata,10000)-d)/100;
y = floor(dYMDdata/10000);

output = (min(y)>=1900 && max(y)<=2100) && (min(m)>0 && max(m)<13) && (min(d)>0 && all(d<=eomday(y,m)));

end

% reference below explains the logic of line 9.
% bYear = min(y)>=1900 && max(y)<=2100;
% if bYear
%     bMonth = min(m)>0 && max(m)<13;
%     if bMonth
%         bDay = min(d)>0 && all(d<=eomday(y,m));
%         if bDay
%             output = 1;
%             return
%         else
%             output = 0;
%             return
%         end
%     else
%         output = 0;
%         return
%     end
% else
%     output = 0;
%     return
% end
