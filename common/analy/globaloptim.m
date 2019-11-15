function [coeff, fval, r2, exitflag] = globaloptim(xdata, ydata, model, lb, ub, ms_startno, ms_parallel)
%% check arguments
if nargin == 5
    ms_startno = 8;
    ms_parallel = 0;
elseif nargin == 6
    ms_parallel = 0;    
end
if size(xdata,1) ~= size(ydata,1)
    ydata = ydata';
end
%% solve problem
x0 = ones(1,length(lb));
problem = createOptimProblem('lsqcurvefit',...
                            'objective',model,...
                            'xdata',xdata,'ydata',ydata,...
                            'x0',x0,...
                            'lb',lb,...
                            'ub',ub);
ms = MultiStart;
ms.UseParallel = ms_parallel;
ms.Display = 'off';
[coeff, fval, exitflag] = run(ms, problem, ms_startno);
%% calculate R^2
ydata_fit = model(coeff, xdata);
r2 = rsquare(ydata, ydata_fit);