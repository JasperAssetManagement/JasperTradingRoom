function data = read_excel_columns(filename,sheet,firstrow,lastrow, varargin)
% Read selected columns from large Excel sheet using ActiveX
% Faster than xlsread and uses less memory in most cases 
%
%  filename :  Name of Excel file. 
%  sheet    :  String or number. e.g. 'Sheet1' or 1 
%  columns  :  array of column numbers or cell array of column letters, 
%              e.g [17,341,784] or {'B', 'AA', 'ABC'}
%              Note the curly brackets: ['B', 'AA'] will give wrong output!
%  firstrow, lastrow:  The first and last rows to be read 
%  data:    :  array of numerical values.  
%              a(:,i) holds the values from columns(i)
%              Non-numeric cells are returned as NaN
%
% Example:
% data = read_excel_columns('Book1.xlsx',1,[4,7,700],2,2000);

% Are Mjaavatten, 2016-03-15

%Setup default values
p.outputAsChar    = false;
p.columns         = [];

validParams     = {     ...
  'columns'     ,       ...
  'outputAsChar',       ...
  };

if nargin > 1
    if mod( numel( varargin ), 2 ) ~= 0
        error( 'csvimport:InvalidInput', ['All input parameters after the fileName must be in the ' ...
         'form of param-value pairs'] );
    end
    params  = lower( varargin(1:2:end) );
    values  = varargin(2:2:end);

    if ~all( cellfun( @ischar, params ) )
    error( 'read_excel_columns:InvalidInput', ['All input parameters after the fileName must be in the ' ...
      'form of param-value pairs'] );
    end

    lcValidParams   = lower( validParams );
    for ii =  1 : numel( params )
        result        = strmatch( params{ii}, lcValidParams );
        %If unknown param is entered ignore it
        if isempty( result )
          continue
        end
        %If we have multiple matches make sure we don't have a single unambiguous match before throwing
        %an error
        if numel( result ) > 1
          exresult    = strmatch( params{ii}, validParams, 'exact' );
          if ~isempty( exresult )
            result    = exresult;
          else
            %We have multiple possible matches, prompt user to provide an unambiguous match
            error( 'csvimport:InvalidInput', 'Cannot find unambiguous match for parameter ''%s''', ...
              varargin{ii*2-1} );
          end
        end
        result      = validParams{result};
        p.(result)  = values{ii};
    end
end
    
    % Get the full path and file name
    file = char(System.IO.Path.GetFullPath(filename));
    if isempty(dir(file))   % Check if file exists
        error('File not found')
    end
    
    % Allocate space for data array
    try  
        hExcel = actxserver('Excel.Application');
        hWorkbook = hExcel.Workbooks.Open(file);
        hWorksheet = hWorkbook.Sheets.Item(sheet);
        
        nrows = lastrow-firstrow+1;
        if isempty(p.columns)
            ncols= hWorksheet.UsedRange.Columns.Count;
            p.columns=1:1:ncols; %default: read all columns
        else
            ncols = length(p.columns);
        end        
        
        if p.outputAsChar
            data = cell( nrows, ncols );
        else        
            data = zeros(nrows,ncols);
        end
    %
    
    first = num2str(firstrow);  
    last = num2str(lastrow);
   
        for i = 1:ncols
            if iscell(p.columns)
                col = p.columns{i};
            else
                col = col2str(p.columns(i));
            end
            Range = [col,first,':',col,last];
            RangeObj = hWorksheet.Range(Range);
            if ~p.outputAsChar
                try
                    data(:,i) = cell2mat(RangeObj.value);
                catch  % If not all cells have numeric values
                    data(:,i) = cellfun(@translate,RangeObj.value);
                end
            else
                if ~iscell(RangeObj.value)
                    data(:,i) = {RangeObj.value};
                else
                    data(:,i) = RangeObj.value;
                end
            end
        end
    catch err% Try-catch ensures that we always reach the cleanup at the end
        fprintf(err.message);
    end
    % Clean up:
    hWorkbook.Close(false);  % Close without saving
    hExcel.Quit();           % Kill the Excel process
end

function [colname] = col2str(n)
% Translate Excel column number to Column characters 
    s = '';
    while n > 0
        s = [s,char(mod(n-1,26)+65)];
        n = floor((n-1)/26);
    end
    colname = deblank(fliplr(s));
end

function y = translate(x)
    % Translate non-numeric values to NaN
    if isnumeric(x)
        y = x;
    else
        y = NaN;
    end
end