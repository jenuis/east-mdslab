function dec = bit2dec(bit_val)
bit_str = '';
for i=1:length(bit_val)
    bit_str(i) = num2str(bit_val(i));
end
dec = bin2dec(bit_str);


% bit_no = logical(bit_no);
% dec =[];
% total_bits = length(bit_no);
% for i=1:total_bits
%     dec(end+1) = 2^(total_bits-i)*bit_no(i);
% end
% dec = sum(dec);