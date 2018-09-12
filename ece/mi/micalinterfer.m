function [data, freq, time, phase] = micalinterfer(refer, interfer)
%% [to do] validation for sliced refer and interfer
    [time, interfer_list] = split_interfer(refer, interfer);

    for i = 1:length(time)
        interfer_list(:,i) = interfer_list(:,i) - mean(interfer_list(:,i));

        [zpdPosition, eta] = getZPDPos(interfer_list(:,i));

        temp_phase = getIndividualPhases(interfer_list(:,i), zpdPosition, eta);

        phase(:,i) = temp_phase;

        [frequency, data(:,i)] = getIndividualSpectraOpt(interfer_list(:,i), temp_phase, zpdPosition, eta);

    %     calibratedSpectra(:,i) = uncalibratedSpectra(:,i)./intensityCalibration.*(600*0.85-34)/(1.16e4);
        freq = frequency/1e9; % unit:GHz
    end
end


function [time, interfer_list] = split_interfer(refer, interfer)

single_interferogram_length = 2484;
turning_point_1 = 886;
turning_point_2 = 1598;
ADCfreq = 75200;

%% Find referenceMarker
RM_number = 0;
referenceMarker_temp = 0;

if max(refer) < 3
    threshold = 1.9;
else
    threshold = 4.6;
end

for i = 1:length(refer)  
      if (refer(i) > threshold && (i-referenceMarker_temp)>100)
        RM_number = RM_number+1;
        referenceMarker(RM_number) = i;
        referenceMarker_temp = referenceMarker(RM_number);
      end
end

%% Distinguish individual interferogram
ReferenceMarker_pair_number = floor(length(referenceMarker)/2);

parameter(1) = ReferenceMarker_pair_number;
parameter(2) = single_interferogram_length;
parameter(3) = turning_point_1;
parameter(4) = turning_point_2;
parameter(5) = ADCfreq;

xx = mod(RM_number,2);
if xx==0
    if referenceMarker(2)-referenceMarker(1) < 2000
        if referenceMarker(1) > turning_point_2 
            if length(interfer)-referenceMarker(end) > turning_point_2 
                [interfer_list,time] = case1(interfer,referenceMarker,parameter);
            else
                [interfer_list,time] = case2(interfer,referenceMarker,parameter);
            end
        else            
            if length(interfer)-referenceMarker(end) > turning_point_2
                [interfer_list,time] = case3(interfer,referenceMarker,parameter);
            else
                [interfer_list,time] = case4(interfer,referenceMarker,parameter);
            end
        end    
    else
        if referenceMarker(1)>turning_point_1
            if length(interfer)-referenceMarker(end)>turning_point_1 
                [interfer_list,time] = case5(interfer,referenceMarker,parameter);
            else
                [interfer_list,time] = case6(interfer,referenceMarker,parameter);
            end
        else
            if length(interfer)-referenceMarker(end)>turning_point_1
                [interfer_list,time] = case7(interfer,referenceMarker,parameter);
            else
                [interfer_list,time] = case8(interfer,referenceMarker,parameter);
            end
        end
    end
else
    if referenceMarker(2)-referenceMarker(1) < 2000
        if referenceMarker(1)>turning_point_2 
            if length(interfer)-referenceMarker(end)>turning_point_1 
                  [interfer_list,time] = case9(interfer,referenceMarker,parameter);
            else
                  [interfer_list,time] = case10(interfer,referenceMarker,parameter);
            end
        else
            if length(interfer)-referenceMarker(end)>turning_point_1
                  [interfer_list,time] = case11(interfer,referenceMarker,parameter);
            else
                 [interfer_list,time] = case12(interfer,referenceMarker,parameter);
            end
        end
    else
        if referenceMarker(1) > turning_point_1
            if length(interfer)-referenceMarker(end) > turning_point_2 
                  [interfer_list,time] = case13(interfer,referenceMarker,parameter);
            else
              [interfer_list,time] = case14(interfer,referenceMarker,parameter);
            end
        else
            if length(interfer)-referenceMarker(end) > turning_point_2
                 [interfer_list,time] = case15(interfer,referenceMarker,parameter);
            else
                  [interfer_list,time] = case16(interfer,referenceMarker,parameter);
            end
        end
    end
end  

%% Case1
function [individualInterferogram,time] = case1(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward = zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward = zeros(ReferenceMarker_pair_number ,1);
individualInterferogram = zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i-1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);       
    time(2*i-1) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;%% 570is turning point 1 -zpd
    time(2*i)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
end  
end
%% Case2
function [individualInterferogram,time] = case2(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward = zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward = zeros(ReferenceMarker_pair_number-1 ,1);
individualInterferogram = zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i-1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;     
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop); 
    time(2*i-1) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
end      
referenceMarker_backward(ReferenceMarker_pair_number) = referenceMarker(end-1);
backward_start = referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+1;
backward_stop = referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+single_interferogram_length;     
individualInterferogram(:,2*ReferenceMarker_pair_number-1) = flipud(interferogramRawData(backward_start:backward_stop));
time(2*ReferenceMarker_pair_number-1) = (referenceMarker_backward(ReferenceMarker_pair_number)+570)./ADCfreq-0.5;
end
%% Case3
function [individualInterferogram,time] = case3(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward = zeros(ReferenceMarker_pair_number-1 ,1);
referenceMarker_forward = zeros(ReferenceMarker_pair_number ,1);
individualInterferogram = zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i+1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;     
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop)); 
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i-1) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end  
referenceMarker_forward(ReferenceMarker_pair_number)=referenceMarker(end);
forward_start = referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+1;
forward_stop = referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+single_interferogram_length;
individualInterferogram(:,2*ReferenceMarker_pair_number-1)= interferogramRawData(forward_start:forward_stop);
time(2*ReferenceMarker_pair_number-1)=(referenceMarker_forward(ReferenceMarker_pair_number)-570)./ADCfreq-0.5;
end
%% Case4
function [individualInterferogram,time] = case4(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward = zeros(ReferenceMarker_pair_number-1,1);
referenceMarker_forward = zeros(ReferenceMarker_pair_number-1,1);
individualInterferogram = zeros(single_interferogram_length,2*ReferenceMarker_pair_number-2);
time = zeros(2*ReferenceMarker_pair_number-2,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i+1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop)); 
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i-1) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end
end
%% Case5
function [individualInterferogram,time] = case5(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);

for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i-1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop));
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end
end
%% Case6
function [individualInterferogram,time] = case6(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number-1 ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
                    
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i-1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop));  
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end
                    
referenceMarker_forward(ReferenceMarker_pair_number)=referenceMarker(end-1);
forward_start =  referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+1;
forward_stop = referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+single_interferogram_length;
individualInterferogram(:,2*ReferenceMarker_pair_number-1) = interferogramRawData(forward_start:forward_stop);
time(2*ReferenceMarker_pair_number-1)=(referenceMarker(end-1)-570)./ADCfreq-0.5;
end
%% Case7
function [individualInterferogram,time] = case7(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number-1 ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i+1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);  
    time(2*i-1)=(referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end  
referenceMarker_backward(ReferenceMarker_pair_number)=referenceMarker(end);
backward_start =  referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+1;
backward_stop = referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+single_interferogram_length;
individualInterferogram(:,2*ReferenceMarker_pair_number-1) = flipud(interferogramRawData(backward_start:backward_stop));
time(2*ReferenceMarker_pair_number-1)=(referenceMarker(end)+570)./ADCfreq-0.5;
end
%% Case8
function [individualInterferogram,time] = case8(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number-1 ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number-1 ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number-2);
time=zeros(2*ReferenceMarker_pair_number-2,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i+1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);  
    time(2*i-1)=(referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end  
end
%% Case9
function [individualInterferogram,time] = case9(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number+1 ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number+1);
time=zeros(2*ReferenceMarker_pair_number+1,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i-1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);  
    time(2*i-1)=(referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end    
referenceMarker_backward(ReferenceMarker_pair_number+1)=referenceMarker(end);
backward_start =  referenceMarker_backward(ReferenceMarker_pair_number+1)-turning_point_2+1;
backward_stop =  referenceMarker_backward(ReferenceMarker_pair_number+1)-turning_point_2+single_interferogram_length;  
individualInterferogram(:,2*ReferenceMarker_pair_number+1) = flipud(interferogramRawData(backward_start:backward_stop));
time(2*ReferenceMarker_pair_number+1)=(referenceMarker(end)+570)./ADCfreq-0.5;
end
%% Case10
function [individualInterferogram,time] = case10(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i-1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;     
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop); 
    time(2*i-1)=(referenceMarker_backward(i)+570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_forward(i)-570)./ADCfreq-0.5;
end   
end
%% Case11
function [individualInterferogram,time] = case11(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i+1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;     
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop)); 
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end  
end
%% Case12
function [individualInterferogram,time] = case12(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number-1 ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i);
    referenceMarker_backward(i) = referenceMarker(2*i+1);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop));   
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end  
referenceMarker_forward(ReferenceMarker_pair_number)=referenceMarker(end-1);
forward_start =  referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+1;
forward_stop = referenceMarker_forward(ReferenceMarker_pair_number)-turning_point_1+single_interferogram_length;
individualInterferogram(:,2*ReferenceMarker_pair_number-1) = interferogramRawData(forward_start:forward_stop);
time(2*ReferenceMarker_pair_number-1)=(referenceMarker(end-1)-570)./ADCfreq-0.5;;
end
%% Case13
function [individualInterferogram,time] = case13(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number+1 ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number+1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i-1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop));   
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end  
referenceMarker_forward(ReferenceMarker_pair_number+1)=referenceMarker(end);
forward_start =  referenceMarker_forward(ReferenceMarker_pair_number+1)-turning_point_1+1;
forward_stop = referenceMarker_forward(ReferenceMarker_pair_number+1)-turning_point_1+single_interferogram_length;
individualInterferogram(:,2*ReferenceMarker_pair_number+1) = interferogramRawData(forward_start:forward_stop);
time(2*ReferenceMarker_pair_number+1)=(referenceMarker(end)-570)./ADCfreq-0.5;
end
%% Case14
function [individualInterferogram,time] = case14(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i-1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = interferogramRawData(forward_start:forward_stop);
    individualInterferogram(:,2*i) = flipud(interferogramRawData(backward_start:backward_stop));  
    time(2*i-1)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end 
end
%% Case15
function [individualInterferogram,time] = case15(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number);
time=zeros(2*ReferenceMarker_pair_number,1);
for i = 1:ReferenceMarker_pair_number
    referenceMarker_forward(i) = referenceMarker(2*i+1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);  
    time(2*i)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i-1) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end  
end
%% Case16
function [individualInterferogram,time] = case16(interferogramRawData,referenceMarker,parameter)

ReferenceMarker_pair_number = parameter(1);
single_interferogram_length = parameter(2);
turning_point_1 = parameter(3);
turning_point_2 = parameter(4);
ADCfreq = parameter(5);

referenceMarker_backward=zeros(ReferenceMarker_pair_number ,1);
referenceMarker_forward=zeros(ReferenceMarker_pair_number-1 ,1);
individualInterferogram=zeros(single_interferogram_length,2*ReferenceMarker_pair_number-1);
time=zeros(2*ReferenceMarker_pair_number-1,1);
for i = 1:ReferenceMarker_pair_number-1
    referenceMarker_forward(i) = referenceMarker(2*i+1);
    referenceMarker_backward(i) = referenceMarker(2*i);
    forward_start =  referenceMarker_forward(i)-turning_point_1+1;
    forward_stop = referenceMarker_forward(i)-turning_point_1+single_interferogram_length;
    backward_start = referenceMarker_backward(i)-turning_point_2+1;
    backward_stop = referenceMarker_backward(i)-turning_point_2+single_interferogram_length;                       
    individualInterferogram(:,2*i-1) = flipud(interferogramRawData(backward_start:backward_stop));
    individualInterferogram(:,2*i) = interferogramRawData(forward_start:forward_stop);  
    time(2*i)=(referenceMarker_forward(i)-570)./ADCfreq-0.5;
    time(2*i-1) = (referenceMarker_backward(i)+570)./ADCfreq-0.5;
end  
referenceMarker_backward(ReferenceMarker_pair_number)=referenceMarker(end-1);
backward_start = referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+1;
backward_stop = referenceMarker_backward(ReferenceMarker_pair_number)-turning_point_2+single_interferogram_length;      
individualInterferogram(:,2*ReferenceMarker_pair_number-1) = flipud(interferogramRawData(backward_start:backward_stop));
time(2*ReferenceMarker_pair_number-1)=(referenceMarker(end-1)+570)./ADCfreq-0.5;
end
end

function [zpdPosition,eta] = getZPDPos(interferogram)
% Find ZPD Position of the interferogram
% Created in 2014.02.11

[~,zpdPosition] = min(abs(max(interferogram)-interferogram));    
% if abs(zpdPosition-315) > 20
%     zpdPosition = 315;
% end
if abs(zpdPosition-300) > 20
    zpdPosition = 300;
end

denominator = -0.5*(interferogram(zpdPosition+1)-interferogram(zpdPosition-1));

numerator = (interferogram(zpdPosition+1)+interferogram(zpdPosition-1)-2*interferogram(zpdPosition));

if numerator ~= 0
    eta = denominator/numerator;
else
    eta = 0;
end

if (abs(eta) > 1) | (isnumeric(eta) == 0)
    eta = 0.0;
end

end

function [phaseFTCosSin] = getIndividualPhases(interferograms,zpdPositions,eta)
% Spectrum analyze
% Created in 2014.02.11

% spatialSamplingIncrement = 20e-6;
PIx2 = 2.0*pi;

lengthDoubleSidedRegion = 512;
  
triangleStandard = zeros(1,lengthDoubleSidedRegion+1);
triangleStandard(1:(lengthDoubleSidedRegion/2+1)) = 1+ linspace(-lengthDoubleSidedRegion/2.0,0,lengthDoubleSidedRegion/2.0+1)/(lengthDoubleSidedRegion/2.0);
triangleStandard((lengthDoubleSidedRegion/2+1):(lengthDoubleSidedRegion+1)) = 1-linspace(0,lengthDoubleSidedRegion/2.0,lengthDoubleSidedRegion/2.0+1)/(lengthDoubleSidedRegion/2.0);

triangleIndividual = zeros(1,lengthDoubleSidedRegion);
doubleSidedRegion = zeros(1,lengthDoubleSidedRegion);

cosTransArrPhase = zeros(1,lengthDoubleSidedRegion);
sinTransArrPhase = zeros(1,lengthDoubleSidedRegion);

phaseFTCosSin = zeros(1,lengthDoubleSidedRegion+1);
   
% counterPackage = 0;
%   
% phasePlusOffset = zeros(1,lengthDoubleSidedRegion+1);
% phase = zeros(1,lengthDoubleSidedRegion+1);

if(eta<0)
    triangleIndividual(1:(lengthDoubleSidedRegion/2)) = triangleStandard(1:(lengthDoubleSidedRegion/2)) - eta/(lengthDoubleSidedRegion/2.0);
    triangleIndividual((lengthDoubleSidedRegion/2+1):lengthDoubleSidedRegion) = triangleStandard((lengthDoubleSidedRegion/2+1):lengthDoubleSidedRegion) + eta/(lengthDoubleSidedRegion/2.0);
    doubleSidedRegion(1:lengthDoubleSidedRegion) = interferograms(zpdPositions-lengthDoubleSidedRegion/2:zpdPositions+lengthDoubleSidedRegion/2-1);
else
    triangleIndividual(1:(lengthDoubleSidedRegion/2)) = triangleStandard(2:(lengthDoubleSidedRegion/2+1)) - eta/(lengthDoubleSidedRegion/2.0);
    triangleIndividual((lengthDoubleSidedRegion/2+1):lengthDoubleSidedRegion) = triangleStandard((lengthDoubleSidedRegion/2+2):lengthDoubleSidedRegion+1) + eta/(lengthDoubleSidedRegion/2.0);
    doubleSidedRegion(1:lengthDoubleSidedRegion) = interferograms(zpdPositions-lengthDoubleSidedRegion/2+1:zpdPositions+lengthDoubleSidedRegion/2);
end
         
meanInter = mean(doubleSidedRegion(1:lengthDoubleSidedRegion));
 
cosTransArrPhase(1:lengthDoubleSidedRegion) = (doubleSidedRegion-meanInter).*triangleIndividual;
 
realImagePhase = fft(cosTransArrPhase,2*lengthDoubleSidedRegion);

cosTransArrPhase =  real(realImagePhase);
sinTransArrPhase = -imag(realImagePhase);

phasePlusOffset_temp = atan2(sinTransArrPhase,cosTransArrPhase);
phasePlusOffset = phasePlusOffset_temp(1:lengthDoubleSidedRegion+1);

if(eta<0)
    shiftDueToEta = 1 + eta;
else
    shiftDueToEta = eta;
end

phase = pi*(lengthDoubleSidedRegion*0.5+shiftDueToEta)*(linspace(0,lengthDoubleSidedRegion,lengthDoubleSidedRegion+1))/(lengthDoubleSidedRegion) - phasePlusOffset;

phaseFTCosSin(1:lengthDoubleSidedRegion+1) = mod(phase+pi,PIx2) - pi;

end

function [frequency,uncalibratedSpectra,interferogram2FFT] = getIndividualSpectraOpt(interferograms,phase,zpdPositions,eta);
% Spectrum analyze
% Created in 2014.02.12

spatialSamplingIncrement = 20e-6;
lengthDoubleSidedRegion = 512;
lengthFullRegion = 8192;
if lengthFullRegion > length(interferograms)
    interferogramsLength = length(interferograms);
else
    interferogramsLength = lengthFullRegion;
end
    
c_mpers = 299790016;

rampStandard = zeros(1,lengthDoubleSidedRegion+1);
rampStandard(1:lengthDoubleSidedRegion+1) = linspace(0,lengthDoubleSidedRegion,lengthDoubleSidedRegion+1)/(lengthDoubleSidedRegion*1.0);

rampIndividual = zeros(1,lengthDoubleSidedRegion);
    
cosStandard = zeros(1,lengthFullRegion);
    
mainWindow = zeros(1,lengthFullRegion);
    
interferogram2FFT = zeros(1,lengthFullRegion);
 
interpolationFactor = floor(lengthFullRegion/lengthDoubleSidedRegion); 
phaseInpolationStepFunction = zeros(1,lengthFullRegion);

for j = 1:lengthFullRegion
    phaseInpolationStepFunction(j) = floor((j-1)/interpolationFactor);
end

maxFrequency = c_mpers/(4.0*spatialSamplingIncrement);
                
deltaFrequency = maxFrequency/lengthFullRegion;

% frequency = zeros(1,lengthFullRegion);
spectra = zeros(1,lengthFullRegion);
    
cosTransArr = zeros(1,lengthFullRegion);
sinTransArr = zeros(1,lengthFullRegion);
    


if((zpdPositions+eta) > (lengthDoubleSidedRegion*0.5))
    if(eta<0)
        lengthSSRegion = interferogramsLength - zpdPositions - lengthDoubleSidedRegion*0.5;
    else
        lengthSSRegion = interferogramsLength - zpdPositions - lengthDoubleSidedRegion*0.5 - 1;
    end
else
    lengthSSRegion = interferogramsLength-lengthDoubleSidedRegion;
end

normFactor = pi*0.5/(lengthSSRegion);
  
if(eta<0)
    rampIndividual(1:lengthDoubleSidedRegion) = rampStandard(1:lengthDoubleSidedRegion) - eta/(lengthDoubleSidedRegion*1.);
    cosStandard(1:lengthSSRegion) = cos((linspace(0,lengthSSRegion-1,lengthSSRegion)-eta)*normFactor);
    interferogram2FFT(1:(lengthDoubleSidedRegion+lengthSSRegion)) = interferograms(zpdPositions-lengthDoubleSidedRegion/2:zpdPositions+lengthDoubleSidedRegion/2+lengthSSRegion-1);
else
    rampIndividual(1:lengthDoubleSidedRegion) = rampStandard(2:(lengthDoubleSidedRegion+1)) - eta/(lengthDoubleSidedRegion*1.);
    cosStandard(1:lengthSSRegion) = cos((linspace(0,lengthSSRegion-1,lengthSSRegion)-eta+1)*normFactor);
    interferogram2FFT(1:(lengthDoubleSidedRegion+lengthSSRegion)) = interferograms(zpdPositions-lengthDoubleSidedRegion/2+1:zpdPositions+lengthDoubleSidedRegion/2+lengthSSRegion);                
end
  
mainWindow(1:lengthDoubleSidedRegion) = rampIndividual(1:lengthDoubleSidedRegion);
mainWindow((lengthDoubleSidedRegion+1):(lengthDoubleSidedRegion+lengthSSRegion)) = cosStandard(1:lengthSSRegion);
    
interferogram2FFT = mainWindow(1:lengthFullRegion).*interferogram2FFT(1:lengthFullRegion);

realImage = fft(interferogram2FFT,2*lengthFullRegion);

cosTransArr = real(realImage);
sinTransArr = -imag(realImage);
spectra2_temp = abs(realImage);
spectra2 = spectra2_temp(1:lengthFullRegion);
            
if(eta<0)
    shiftDueToEta = 1 + eta;
else
    shiftDueToEta = eta;
end

factor = pi*((lengthDoubleSidedRegion*0.5+shiftDueToEta))/lengthFullRegion;
   
for j = 1:lengthFullRegion
    zp(j) = phase(phaseInpolationStepFunction(j)+2) - phase(phaseInpolationStepFunction(j)+1);
end
%zp = phase(phaseInpolationStepFunction(1:lengthFullRegion)+1) - phase(phaseInpolationStepFunction(1:lengthFullRegion));

zp2 = (linspace(0,lengthFullRegion-1,lengthFullRegion)-phaseInpolationStepFunction(1:lengthFullRegion)*interpolationFactor)/(interpolationFactor*1.);
zp3 = zp.*zp2+phase(int16(phaseInpolationStepFunction(1:lengthFullRegion))+1);
zp4 = zp3 - linspace(0,lengthFullRegion-1,lengthFullRegion)*factor;
zp5 = mod(zp4-pi,2*pi)+pi;
            
specCos =  cosTransArr(1:lengthFullRegion).*cos(zp5);
specSin = -sinTransArr(1:lengthFullRegion).*sin(zp5);
            
spectra(1:lengthFullRegion) = specCos(1:lengthFullRegion)+specSin(1:lengthFullRegion);

frequency = linspace(0,lengthFullRegion-1,lengthFullRegion)*deltaFrequency;

uncalibratedSpectra = spectra*spatialSamplingIncrement;

end
