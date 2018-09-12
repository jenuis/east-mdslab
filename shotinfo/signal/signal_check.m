function signal = signal_check(signal)
if isobject(signal)
    signal = checkobj(signal);
else
    signal = checknormal(signal);
end

function signal = checknormal(signal)
signal.status = 0;
if isempty(signal.time) || ischar(signal.time) || length(signal.time) ~= length(signal.data)
    signal.time = [];
    signal.data = [];
    return
end
signal.status = 1;

function status = checkobj(signal)
status = 0;
if isempty(signal.time) || ischar(signal.time) || length(signal.time) ~= length(signal.data)
    signal.time = [];
    signal.data = [];
    return
end
status = 1;