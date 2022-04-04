function dy=central_diff2(y,deltat,d,a)
% https://www.mathworks.com/matlabcentral/fileexchange/48520-central_diff2-y-deltat-d-a
% Calculates dth derivative of y to accuracy order deltat^a
% deltat is the sampling period of y
% a must be even

% For boundary values, forward or semicentral diff. is used - accuracy is
% maintained to deltat^a

% Benjamin Strom, 11/19/2014
%% Error check
if mod(a,2)
    error('accuracy, a, must be even')
end

% need to calculate minimum number of values of y necessary

%% Calculate coefficients

ne=d+a; % Number of terms for boundary finite diffs
ncd=2*floor((d+1)/2)-1+a; % Number of terms for center diff.

% Get forwardish diff. coeffs untill central diff can take over
At=ones(ne,ne);
b=zeros(ne,1);
b(d+1)=1;
Ct=zeros(floor(ncd/2),ne);
for m=1:floor(ncd/2)
    xrowt=(1:ne)-m;
    for i=2:ne
        At(i,:)=(xrowt.^(i-1))./factorial(i-1);
    end
    Ct(m,:)=(At\b)';
end
Cb=rot90(Ct,2).*(-1)^d; % 

% Central diff. coeff.s
Ac=ones(ncd,ncd);
xrowc=-(floor(ncd/2)):floor(ncd/2);
for i=2:ncd
    Ac(i,:)=(xrowc.^(i-1))./factorial(i-1);
end
b=zeros(ncd,1);
b(d+1)=1;
Cc=(Ac\b)';
%% construct sparse matrix A, where y'=Ay
p=length(y);

B=repmat(Cc,p,1);

A=spdiags(B,-floor(ncd/2):floor(ncd/2),p,p);
A(1:floor(ncd/2),1:ne)=Ct;
A(p-floor(ncd/2)+1:p,p-ne+1:p)=Cb;
y=reshape(y,p,1);
dy=(A*y)./deltat(:).^d;
end