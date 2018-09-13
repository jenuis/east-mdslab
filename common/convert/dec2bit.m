function bit_val = dec2bit(dec, bits_no)
bin_str = dec2bin(dec);
bit_val = [];
for i=1:length(bin_str)
    bit_val(i) = str2double(bin_str(i));
end
bit_val = logical(bit_val);
if nargin == 2 && length(bit_val) < bits_no
    bit_val = flip(bit_val);
    bit_val(end+1:end+bits_no-length(bit_val)) = false;
    bit_val = flip(bit_val);
end