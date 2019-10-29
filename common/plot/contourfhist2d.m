% function h = contourfhist2d(xdata, ydata, nbins)
function [h,hc] = contourfhist2d(xdata, ydata, nbins_x, nbins_y)

% [~,x] = hist(xdata, nbins);
% [~,y] = hist(ydata, nbins);
% c = histcounts2(xdata, ydata, nbins);

if nargin == 3
    nbins_y = nbins_x;
end

x = linspace(min(xdata),max(xdata),nbins_x);
y = linspace(min(ydata),max(ydata),nbins_y);
c = histcounts2(xdata, ydata, x, y);

dx = x(2)-x(1);
dy = y(2)-y(1);

x_cent = x(1:end-1) + dx/2;
y_cent = y(1:end-1) + dy/2;

h = contourfjet(x_cent, y_cent, c');
% cm = flipud(hot);
% colormap(cm);
hc = colorbar;
ylabel(hc, 'Counts'); 