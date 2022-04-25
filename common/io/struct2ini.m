function struct2ini(filename,Structure)
% https://ww2.mathworks.cn/matlabcentral/fileexchange/22079-struct2ini?s_tid=srchtitle
%==========================================================================
% Author:      Dirk Lohse ( dirklohse@web.de )
% Version:     0.1a
% Last change: 2008-11-13
% Modified by Xiang Liu@2022-04-25
%==========================================================================
%
% struct2ini converts a given structure into an ini-file.
% It's the opposite to Andriy Nych's ini2struct. Only 
% creating an ini-file is implemented. To modify an existing
% file load it with ini2struct.m from:
%       Andriy Nych ( nych.andriy@gmail.com )
% change the structure and write it with struct2ini.
%

% Open file, or create new file, for writing
% discard existing contents, if any.

Sections = fieldnames(Structure);                     % returns the Sections
bit_not_section = false(size(Sections));
for i=1:length(Sections)
    if ischar(Structure.(Sections{i}))
        bit_not_section(i) = true;
    end
end
Sections = [Sections(bit_not_section); Sections(~bit_not_section)];

fid = fopen(filename,'w'); 
for i=1:length(Sections)
   Section = Sections{i};
   member_struct = Structure.(Section);               % returns members of Section
   
   if ischar(member_struct)
       member_name = Section;
       member_value = member_struct;
       fprintf(fid,'%s = %s\n',member_name,member_value);
       continue
   end
   
   fprintf(fid,'\n[%s]\n', Section);            % output [Section]
   
   if ~isempty(member_struct)                         % check if Section is empty
      member_names = fieldnames(member_struct);
      for j=1:length(member_names)
         member_name = member_names{j};
         member_value = member_struct.(member_name);
         
         if isnumeric(member_value)
             member_value = num2str(member_value);
         end
         
         fprintf(fid,'%s = %s\n',member_name,member_value); % output member name and value
         
      end % for-END (Members)
   end % if-END
end % for-END (Sections)

fclose(fid); % close file