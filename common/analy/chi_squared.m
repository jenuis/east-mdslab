function [chi2, df] = chi_squared(y,fit,P,eb, varargin)
% https://ww2.mathworks.cn/matlabcentral/fileexchange/1049-chi_squared-m?s_tid=ta_fx_results
% returns *reduced* chi^2 value for use in data modelling
% "y" is a vector of data, "fit" is a vector of model values (size(fit)=size(y)), P is the number of
% parameters fit in the model, and eb is a vector of error bars (1-to-1 correspondnce with y)
% Ref: John R. Taylor, "An Introduction to Error Analysis", (2nd ed., 1997)
% 11/11/01 Mike Scarpulla.  Please direct questions or comments to scarps@uclink.berkeley.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3
    error('Wrong number of arguments passed to "chi_squared"')
end
if nargin<4
    eb = [];
end

Args.OmitNaN = 0;
Args = parseArgs(varargin, Args, {'OmitNaN'});

if Args.OmitNaN
    inds_nan = isnan(y);
    inds_nan = isnan(fit) | inds_nan;
    if ~isempty(eb)
        inds_nan = isnan(eb) | inds_nan;
    end
    y = y(~inds_nan);
    fit = fit(~inds_nan);
    if ~isempty(eb)
        eb = eb(~inds_nan);
    end
end

% if error bars are not availible, evaluate chi^2 by normalizing deviation^2 by magnitude of data.
% This assumes that the STDEV of a value scales as SQRT(value).  USE WITH THIS CAVEAT IN MIND
if isempty(eb)
    N = max(size(y));
    df = N-P;
    terms = ((y-fit).^2)./abs(y);
    chi2 = 1/df*sum(terms);
    return
end

%if error bars are availible, normalize the deviation to the expectred error
N = max(size(y));
df = N-P;
terms = ((y-fit)./eb).^2;
chi2 = 1/df*sum(terms);

