function pow_bit = genpowbit(pow_info, order)
if nargin == 1
    order = {'ecrh', 'icrf', 'lhw', 'nbi'};
    order_alt = {'ech', 'icrf', 'lhw', 'nbi'};
end
pow_bit = [];
for i=1:length(order)
    try
        pow = pow_info.(order{i});
    catch
        pow = pow_info.(order_alt{i});
    end
    if pow
        curr_bit = 1;
    else
        curr_bit = 0;
    end
    pow_bit(i) = curr_bit;
end

pow_bit = bit2dec(pow_bit);