function str = strrmsymbol(str)
str = regexprep(str,'[^a-zA-Z0-9]','');