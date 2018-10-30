function output = isGoodDatenumInput(Y,M,D)
% This function checks if Y, M and D together are valid combinations of 
% years, months and days. Below are some examples.
% isGoodDatenumInput([2013;2013],[2;2],[28;29]) returns false;
% isGoodDatenumInput([2013;2016],[2;2],[28;29]) returns true;
% isGoodDatenumInput([2013;2016],[13;12],[28;29]) returns false;
if ~isequal(size(Y),size(M)) || ~isequal(size(M),size(D))
    error('Sizes of inputs are not the same.')
end
if ~isa(Y,'double') || ~isa(M,'double') || ~isa(D,'double')
    error('Invalid type of inputs.')
end
output = all(M>0) && all(M<13) && all(D>0) && all(D<=eomday(Y,M));
end