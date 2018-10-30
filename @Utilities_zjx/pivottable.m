function out = pivottable(inMatrix, pivotRow, varargin)
%PIVOTTABLE Group a matrix into a pivot table, is flexible as in Excel
%
% out = pivottable(inMatrix, pivotRow, pivotColumn, valueColumn, valueFun) group
% the input matrix "inMatrix" into a pivottable similar with Excel. Anyone
% who are familiar with the pivottable in Excel will not have difficulties
% with this function.
%
% How the pivottables created are shown in following examples:
% let 
%     inMatrix = {
%         '2009', 'Mon', 12, 31;
%         '2009', 'Wed', 11, 34;
%         '2009', 'Fri', 1, 4;
%         '2009', 'Mon', 3, 4;
%         '2009', 'Wed', 9, 6;
%         '2009', 'Fri', 1, 4;
%         '2010', 'Mon', 18, 15;
%         '2010', 'Wed', 11, 21;
%         '2010', 'Wed', 1, 4;    
%         };
% then
%     pivottable(inMatrix, 1, 2, 3, @sum) output a cell
%             []    'Fri'    'Mon'    'Wed'
%         '2009'    [  2]    [ 15]    [ 20]
%         '2010'       []    [ 18]    [ 12]
%     pivottable(inMatrix, [1 2], [], 3, @sum) output a cell
%         '2009'    'Fri'    [ 2]
%         '2009'    'Mon'    [15]
%         '2009'    'Wed'    [20]
%         '2010'    'Mon'    [18]
%         '2010'    'Wed'    [12]    
%     pivottable(inMatrix, [], 2, 3, @sum) output a cell
%         'Fri'    'Mon'    'Wed'
%         [  2]    [ 33]    [ 32]
%     pivottable(inMatrix, 1, 2, [3 4], {@sum, @(x)(numel(x))})
%             []    'Fri'    'Fri'    'Mon'    'Mon'    'Wed'    'Wed'
%         '2009'    [  2]    [  2]    [ 15]    [  2]    [ 20]    [  2]
%         '2010'       []       []    [ 18]    [  1]    [ 12]    [  2]    
%
% author: zhang@zhiqiang.org, http://zhiqiang.org/blog/it/pivottable-in-matlab.html
% version: 2011-02-28 ver 1

if nargin == 5
    pivotColumn = varargin{1};
    valueColumn = varargin{2};
    valueFun = varargin{3};
else
    pivotColumn = [];
    valueColumn = varargin{1};
    valueFun = varargin{2};
end

inMatrix = sortrows(inMatrix, [pivotRow pivotColumn]);
if isnumeric(inMatrix), inMatrix = num2cell(inMatrix); end
if ~iscell(valueFun), valueFun = {valueFun}; end

inN = cell2mat(inMatrix(:, valueColumn));

out = [];
N = numel(pivotRow);
M = numel(valueColumn);

tmp = cell(1, N + M);

s = 1;

if isempty(pivotColumn)
    while s <= size(inMatrix, 1)
        i = s + 1;
        while i <= size(inMatrix, 1) && isequal(inMatrix(i, pivotRow), inMatrix(s, pivotRow))
            i = i + 1;
        end
        
        tmp(1:N) = inMatrix(s, pivotRow);
        
        for j = 1:M
            tmp{N+j} = feval(valueFun{j}, inN(s:i-1, j));
        end
        
        out = [out; tmp];
        s = i;
    end
else
    % 先构造out矩阵的行头和列头，其中前numel(pivotColumn)行为pivotRow列对应的值，
    % 前numel(pivotRow)列为pivotColumn列对应的值
    out = cell(numel(pivotColumn), numel(pivotRow));
    
    % 构造列头
    s = 1;
    while s <= size(inMatrix, 1)
        i = s + 1;
        while i <= size(inMatrix, 1) && isequal(inMatrix(i, pivotRow), inMatrix(s, pivotRow))
            i = i + 1;
        end
        
        out = [out; inMatrix(s, pivotRow)];
        s = i;
    end
    
    
    % 构造行头，行头从第numel(pivotRow) + 1列开始
    % 注意，每个行头会重复numel(valueColumn)次
    in1 = sortrows(inMatrix, pivotColumn);
    t = 1; k = numel(pivotRow) + 1;
    while t <= size(in1, 1)
        i = t + 1;
        while i <= size(in1, 1) && isequal(in1(i, pivotColumn), in1(t, pivotColumn))
            i = i + 1;
        end
        
        for r = k:k+numel(valueColumn)-1
            out(1:numel(pivotColumn), r) = in1(t, pivotColumn)';
        end
        
        k = k + numel(valueColumn);
        t = i;
    end

    % 此处开始填写实际值
    % 首先还是先循环每行，先找出pivotColumn一样的行，在这些行里再进行分类
    s = 1; ks = numel(pivotColumn);
    while s <= size(inMatrix, 1)
        i = s + 1;
        ks = ks + 1;
        while i <= size(inMatrix, 1) && isequal(inMatrix(i, pivotRow), inMatrix(s, pivotRow))
            i = i + 1;
        end
        
        % 至此处第[s:i-1]行的pivotColumn列值完全一样，下面再对着i-s行根据
        % pivotRow列值进行细分
        t = s;
        k = numel(pivotRow) + 1;
        while t < i
            j = t + 1;
            while j < i && isequal(inMatrix(j, pivotColumn), inMatrix(t, pivotColumn))
                j = j + 1;
            end
            
            % 至此处第[t:j-1]行的pivotColumn、pivotRow列值完全一样
            while ~isequal(inMatrix(t, pivotColumn), out(1:numel(pivotColumn), k)')
                k = k + numel(valueColumn);
            end

            for r = 1:numel(valueColumn)
                try
                    out{ks, k + r - 1} = feval(valueFun{r}, cell2mat(inMatrix(t:j-1, valueColumn(r))));
                catch
                    out(ks, k + r - 1) = feval(valueFun{r}, inMatrix(t:j-1, valueColumn(r)));
                end
            end

            t = j;
        end
        
        s = i;
    end    
end