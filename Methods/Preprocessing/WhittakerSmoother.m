% Method: WhittakerSmoother
%  -Asymmetric least squares baseline correction
%
% Syntax
%   baseline = WhittakerSmoother(y)
%   baseline = WhittakerSmoother(y, 'OptionName', optionvalue...)
%
% Options
%   'smoothness' : 10^3 to 10^9
%   'asymmetry'  : 10^-1 to 10^-6
%
% Description
%   y            : array or matrix
%   'smoothness' : 10^3 to 10^9
%   'asymmetry'  : 10^1 to 10^-6
%
% Examples
%   baseline = WhittakerSmoother(y)
%   baseline = WhittakerSmoother(y, 'asymmetry', 10^-2)
%   baseline = WhittakerSmoother(y, 'smoothness', 10^5)
%   baseline = WhittakerSmoother(y, 'smoothness', 10^7, 'asymmetry', 10^-3)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function baseline = WhittakerSmoother(y, varargin)

% Check number of inputs
if nargin < 1
    error('Not enough input arguments');
elseif nargin > 5
    error('Too many input arguments');
end  

% Check data
if ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
end

% Check input
if nargin == 1
    
    % Default pararmeters
    smoothness = 10^6;
    asymmetry = 10^-6;
    
% Check options
elseif nargin > 1
    
    % Check smoothness options
    if ~isempty(find(strcmpi(varargin, 'smoothness'),1));
        smoothness = varargin{find(strcmpi(varargin, 'smoothness'),1) + 1};

        % Check user input
        if ~isnumeric(smoothness)
            error('Undefined input arguments of type ''smoothness''');
        end 
    else
        % Default smoothness options
        smoothness = 10^6;
    end
    
    % Check asymmetry options
    if ~isempty(find(strcmpi(varargin, 'asymmetry'),1));
        asymmetry = varargin{find(strcmpi(varargin, 'asymmetry'),1) + 1};

        % Check user input
        if ~isnumeric(asymmetry)
            error('Undefined input arguments of type ''asymmetry''');
        elseif asymmetry >= 1
            asymmetry = 0.99;
        end
    else
        % Default smoothness options
        asymmetry = 10^-6;
    end
end

% Ensure y is double precision
y = double(y);

% Perform baseline calculation on each vector
for i = 1:length(y(1,:))
    
    % Correct for negative y-values
    if min(y(:,i)) < 0
        correction = abs(min(y(:,i)));
        y(:,i) = y(:,i) + correction;
    % Correct for non-positive definite y-values
    elseif max(y(:,i)) == 0
        return
    else 
        correction = 0;
    end
    
    % Get length of y vector
    length_y = length(y(:,i));

    % Initialize variables needed for calculation
    diff_matrix = diff(speye(length_y), 2);
    weights = ones(length_y, 1);

    % Pre-allocate memory for baseline
    baseline(:,i) = zeros(length_y, 1);

    % Number of iterations
    for j = 1:10
            
        % Sparse diagonal matrix
        weights_diagonal = spdiags(weights, 0, length_y, length_y);
        
        % Cholesky factorization
        cholesky_factor = chol(weights_diagonal + smoothness * diff_matrix' * diff_matrix);
        
        % Left matrix divide, multiply matrices
        baseline(:,i) = cholesky_factor \ (cholesky_factor' \ (weights .* y(:,i)));
        
        % Reassign weights
        weights = asymmetry * (y(:,i) > baseline(:,i)) + (1 - asymmetry) * (y(:,i) < baseline(:,i));
    end
    
    % Correct for negative y-values
    y(:,i) = y(:,i) - correction;
end
end