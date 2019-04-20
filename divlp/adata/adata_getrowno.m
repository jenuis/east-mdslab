function row_no = adata_getrowno(row_name)
row_name = parse_str_option(row_name);
switch row_name
    case {'lam', 'lambda','lamjs','lambdajs'}
        row_no = 1;
    case {'lamerr', 'lambdaerr', 'lamstd', 'lambdastd','lambdajserr','lambdajsstd'}
        row_no = 2;
    case {'ip'}
        row_no = 3;
    case {'bp'}
        row_no = 4;
    case {'bt'}
        row_no = 5;
    case {'ne'}
        row_no = 6;
    case {'p','pin','pinput','ptotal','ptot','psol'}
        row_no = 7;
    case {'kappa'}
        row_no = 8;
    case {'deltatop'}
        row_no = 9;
    case {'q','q95','qcyl'}
        row_no = 10;
    case {'lxtari','lxtarin','lxtargetin','lin','li'}
        row_no = 11;
    case {'lxtaro','lxtarout','lxtargetout','lout','lo'}
        row_no = 12;
    case {'shot','shotno'}
        row_no = 13;
    case {'s','sjs'}
        row_no = 14;
    case {'sstd','serr','sjsstd','sjserr'}
        row_no = 15;
    case {'powbit'}
        row_no = 16;
    case {'peak','peakjs','jspeak'}
        row_no = 17;
    case {'laminteich','lambdainteich'}
        row_no = 18;
    case {'wmhd'}
        row_no = 19;
    case {'da','dalpha'}
        row_no = 20;
    case {'r2','r2min'}
        row_no = 21;
    case {'t','time'}
        row_no = 22;
    case {'pecrh','pech', 'pec'}
        row_no = 23;
    case {'picrf'}
        row_no = 24;
    case {'plhw'}
        row_no = 25;
    case {'pnbi'}
        row_no = 26;
    case {'tet','tediv','tetar','divte'}
        row_no = 27;
    case {'rpeak','r0'}
        row_no = 28;
    case {'r','majorradius','majorr'}
        row_no = 29;
    case {'a','minorradius','minorr'}
        row_no = 30;
    case {'v', 'vloop', 'vp'}
        row_no = 31;
    case {'needge'}
        row_no = 32;
    case {'prad','powrad','powerrad'}
        row_no = 33;
    case {'te0','tecore'}
        row_no = 34;
    case {'betap'}
        row_no = 35;
    case {'betat'}
        row_no = 36;
    case {'lambdaintraw','lamintraw'}
        row_no = 37;
    case {'deltabot','deltabottom'}
        row_no = 38;
%     case {''}
%         row_no = ;
%     case {''}
%         row_no = ;
%     case {''}
%         row_no = ;
%     case {''}
%         row_no = ;
%     case {''}
%         row_no = ;
    otherwise
        error(sprintf('Unrecognized data name "%s" !',row_name));
end