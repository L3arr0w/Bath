% TASK 1

%% 1.1- Simple connection with arduino board
clc, clearvars, close all

b = arduino ('COM3', 'Uno','Libraries', {'Servo','Ultrasonic'})
u = ultrasonic(b, 'D5','D6')

%% 1.2- Read distance measurements in matlab
clc, clearvars, close all

b = arduino ('COM3', 'Uno','Libraries', {'Servo','Ultrasonic'}); 
u = ultrasonic(b, 'D5','D6');
% creating a simple matrix of measurement distance and time

%parameter config
time = 10
%measuring time
tic
n = 1 
while toc<time;
    data(1,n) = readDistance(u)
    data(2,n) = toc;
    n = n+1;
    pause(0.1) 
end 
data

%% 1.3- Moving average mean to filter results after FIXED dist. readings

clc, clearvars, close all

b = arduino ('COM3', 'Uno','Libraries', {'Servo','Ultrasonic'}); 
u = ultrasonic(b, 'D5','D6');
% parameter config
t = 10
%measuring distance
tic
n=1
while toc<t
    distance(1,n) = readDistance(u)
    time(1,n) = toc;
    n = n+1;
    pause(0.1)
end
%filtering out infinite distance readings
noInfDistance = distance(~isinf(distance))
time2 = time(~isinf(distance))
%using a moving average technique with window size 5
meanDistance = movmean(noInfDistance, 5)
% visual representation of the data
plot(time2,noInfDistance,'*'), hold on
plot(time2,meanDistance)
ylim([0,4])
legend('Distance with inf values removed', ['Distance with moving average ' ...
    'applied and inf values removed'], 'location', 'best')
xlabel('time (s)')
ylabel('Distance (m)')

%% 1.4- Recalibrating the sensor by comparing it to actual distances

% creating a matrix 'data' which contains the actual distance in the 1st row, each with 'w' readings from the sensor below them.

% data created with an input/output, program gives distance to place sensor at, and you enter a value to automate the sensor's reading
% other values can be inputed to repeat previous readings, break the loop, or continue to the next column/distance

% data then processed to find the calibration relationship
clc, clearvars except 'meanDiff', close all
%board config
b = arduino ('COM3', 'Uno','Libraries', {'Servo','Ultrasonic'}); 
u = ultrasonic(b, 'D5','D6');
%config of parameters
wind = 10
startval = 25
endval = 80 % in cm
spacing = 5
%creation of data array
distval = [startval: spacing: endval]
data = zeros(wind+1, size(distval,2));
data(1,:) = distval;
% filling of data
n = 1
while true
    X = ['Distance to wall = ', num2str(data(1,n)), 'cm. Press 1 to confirm,' ...
        ' 2 to repeat, 3 to skip ahead, or 9 to process results.'];
    conf = input(X); %to confirm that sensor is at right distance and/or to repeat the measuring of some data
    if conf == 1
        for w = 1:wind
            data(w+1,n) = readDistance(u)*100               %to use when calibrating
            %data(w+1,n) = (readDistance(u)+meanDiff)*100   %to use when calibrated
            pause(0.1)
        end
        n = n+1
    elseif conf == 3 
        n = n+1;
    elseif conf == 2
        n = n-1;
    elseif conf == 9
        break
    else 
        n = n-1;
    end
    if n > size(data,2)
       n = size(data,2)
    end
end
% find mean of all data collected (whilst excluding all inf values)
n = 1;
while n<= size(data,2)
    meandata(1,n) = data(1,n);
    vals = data(2:wind+1,n);
    vals = vals(~isinf(vals));
    meandata(2,n) = mean(vals);
    n = n+1;
end
%visual representation of data
x = [1:size(meandata,2)];
meandata
plot(x,meandata(1,:)), hold on
plot(x,meandata(2,:))
legend('Real Distance', 'Distance measuured with ultrasonic', 'location', 'best')
xlabel('Arbitrary values')
ylabel('Distance (cm)')
%use this to find relationship between real and read distances --> linear
%finding the mean difference between real and measured values
meanDiff = sum(meandata(2,:)-meandata(1,:))/size(meandata,2)
% WORKS !!!

%% TASK 2

% Investigation of beam angle constraints
% using the resolution of 0.3cm given in datasheet

% Sensor records 'w' number of distance readings at angle 'a' in an angular range 'range',
% angle changes at a resolution 'res'. 

% columns in data array referred to by 'n'

% data collected in 'data' array. 1st row = angle. 2nd row is angles/180. 'w' rows after = distance readings. last row is processed data
% readings then processed to find the angle at which readings no longer
% have a 0.3cm resolution/the sensor returns 'inf' or invalid angle values --> all valid angles are stored in the 'crit' array
% the 'big loop' calculates the mean of multiple angle constraints by repeating the whole code

clc, clearvars, close all
 
 b = arduino ('COM3', 'Uno','Libraries', {'Servo', 'Ultrasonic'}); 
 u = ultrasonic(b, 'D5','D6');
 s = servo(b, 'D3');
% parameters
w = 15              %num. of readings per angle
res = 0.5           %servo angular resolution
range = [-17,17]    %distance range    
threshold = 0.3/100 %the critical std. limit
loops = 5           %number of times code is run
% graph
figure
plot(range(1,1):1:range(1,2), threshold*ones(numel([range(1,1):1:range(1,2)])),'LineStyle','--','Color',[110,0,250]/250,'LineWidth',1), hold on
xlim([range(1,1),range(1,2)])
% big loop
m = 1
while m <= loops
    % configuring 'data'
    distval = [range(1,1):res:range(1,2)]
    data = zeros(w+3, size(distval,2))
    data(1,:) = distval
    data(2,:) = (distval +90)/180
    % collecting data
    n = 1
    while n<=size(data,2)
        writePosition(s,data(2,n))
        pause(0.2)
        for i = 3:w+2
            data(i,n) = readDistance(u)
            pause(0.1)
        end
        n = n+1
    end
    %processing data
    n = 1
    crit = zeros(1,size(data,2))
    while n<= size(data,2)
        vals = data(3:w+2,n)
        vals = vals(~isinf(vals))
        data(w+3,n) = std(vals);
        if std(vals) < threshold && numel(vals) > 0.6*w
            crit(1,n) = data(1,n)
        else
            crit(1,n) = 0
        end
        n = n+1;
    end
    % simple visual representation of data (x-axis = angle, y-axis = std)
    plot(data(1,:),data(w+3,:)), ylim([0,threshold*1.2])
    % finding limits for resolution
    lowerLim = min(crit)
    upperLim = max(crit)
    angularLim(1,m) = (-lowerLim+upperLim)/2 % the mean of both upper and lower means that the sensor doesn't have to be totally square to target
    m = m+1
end
    xlabel('Angle /degrees')
    ylabel('Standard Deviation/m')
    title('Visualisation of data')
    legend('Datasheet sensor resolution')
    angularLim
    meanAngularLim =  sum(angularLim)/size(angularLim,2)


%% TASK 3

% make an LED flash at increasing rate the closer it is to an object
clc
clearvars
close all
b= arduino ('COM3', 'Uno','Libraries', {'Servo', 'Ultrasonic'}); %board configuration
u = ultrasonic(b, 'D5','D6');
%param config
minDist = 1.4 %metres
maxDist = 1.8
time = 100 %time active
wind = 1   %how many measurements per blink
on = 0.06  %time led is on
minOff = 0 %min time led is off
maxOff = 1.5 %max time led is off
%loop
actTime = 0 %time var
off = 0
while actTime < time
    tic;
    for n = 1:wind
        dist(1,n) = readDistance(u)
    end
    noInfDist = dist(~isinf(dist));
    meanDist = mean(noInfDist);
    writeDigitalPin(b,'D2',0);
    if meanDist > minDist && meanDist < maxDist
        toc;
        off = ((meanDist-minDist)*(maxOff-minOff))/(maxDist-minDist)+minOff;
        info = [meanDist,off]
        pause(off);
    else
        pause(off)
    end
    writeDigitalPin(b,'D2',1)
    pause(on)
    actTime = actTime + toc;
end
writeDigitalPin(b,'D2',0) 