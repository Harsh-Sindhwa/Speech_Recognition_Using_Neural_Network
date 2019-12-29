function varargout = speechrecognition(varargin)
% SPEECHRECOGNITION MATLAB code for speechrecognition.fig
%      SPEECHRECOGNITION, by itself, creates a new SPEECHRECOGNITION or raises the existing
%      singleton*.
%
%      H = SPEECHRECOGNITION returns the handle to a new SPEECHRECOGNITION or the handle to
%      the existing singleton*.
%
%      SPEECHRECOGNITION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPEECHRECOGNITION.M with the given input arguments.
%
%      SPEECHRECOGNITION('Property','Value',...) creates a new SPEECHRECOGNITION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before speechrecognition_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to speechrecognition_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help speechrecognition

% Last Modified by GUIDE v2.5 08-Mar-2012 14:28:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @speechrecognition_OpeningFcn, ...
                   'gui_OutputFcn',  @speechrecognition_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end
% --- Executes just before speechrecognition is made visible.
function speechrecognition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to speechrecognition (see VARARGIN)

% Choose default command line output for speechrecognition
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes speechrecognition wait for user response (see UIRESUME)
% uiwait(handles.figure1);
clear a;
global a;
a=arduino('COM5');
a.pinMode(5,'output');
a.pinMode(6,'output');
a.pinMode(7,'output');
a.pinMode(8,'output');
end

% --- Outputs from this function are returned to the command line.
function varargout = speechrecognition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Fs=8000;
for k=1:30
    clear y1 y2 y3;
display('record voice');
pause();
x=wavrecord(Fs,Fs);
t=0.04;
j=1;
y1=0;
for i=1:8000
    if(abs(x(i))>t)
        y1(j)=x(i);
        j=j+1;
    end
end
y2=y1/(max(abs(y1)));
y3=[y2,zeros(1,3120-length(y2))];
y=filter([1 -0.9],1,y3');%high pass filter to boost the high frequency components
%%frame blocking
blocklen=240;%30ms block
overlap=80;
block(1,:)=y(1:240);
for i=1:18
    block(i+1,:)=y(i*160:(i*160+blocklen-1));
end
w=hamming(blocklen);
for i=1:19
    ab=xcorr((block(i,:).*w'),12);%finding auto correlation from lag -12 to 12
    for j=1:12
        auto(j,:)=fliplr(ab(j+1:j+12));%forming autocorrelation matrix from lag 0 to 11
    end
    z=fliplr(ab(1:12));%forming a column matrix of autocorrelations for lags 1 to 12
    alpha=pinv(auto)*z';
    lpc(:,i)=alpha;
end
wavplay(x,Fs);
X(k,:)=reshape(lpc,1,228);
Y(k,:)=input('enter the number ');
end
save('lpcdata.mat','X','Y');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input_layer_size  = 228;  % 20x20 Input Images of Digits
hidden_layer_size = 25;   % 25 hidden units
num_labels = 10;          % 10 labels, from 1 to 10  
load 'normlpcdatabase.mat';
X=K;
Y=L;
m = size(X, 1);
fprintf('\nInitializing Neural Network Parameters ...\n')

initial_Theta1 = randInitializeWeights(input_layer_size, hidden_layer_size);
initial_Theta2 = randInitializeWeights(hidden_layer_size, num_labels);

% Unroll parameters
initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];
fprintf('\nChecking Backpropagation... \n');

%  Check gradients by running checkNNGradients
checkNNGradients;

fprintf('\nProgram paused. Press enter to continue.\n');
pause;
fprintf('\nTraining Neural Network... \n')

%  After you have completed the assignment, change the MaxIter to a larger
%  value to see how more training helps.
options = optimset('MaxIter',150);

%  You should also try different values of lambda
lambda = 0.6;

% Create "short hand" for the cost function to be minimized
costFunction = @(p) nnCostFunction(p, ...
                                   input_layer_size, ...
                                   hidden_layer_size, ...
                                   num_labels, X, Y, lambda);

% Now, costFunction is a function that takes in only one argument (the
% neural network parameters)
[nn_params, cost] = fmincg(costFunction, initial_nn_params, options);

% Obtain Theta1 and Theta2 back from nn_params
Theta1 = reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                 hidden_layer_size, (input_layer_size + 1));

Theta2 = reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                 num_labels, (hidden_layer_size + 1));

fprintf('Program paused. Press enter to continue.\n');
pause;


%% ================= Part 9: Visualize Weights =================
% %  You can now "visualize" what the neural network is learning by 
% %  displaying the hidden units to see what features they are capturing in 
% %  the data.
% 
% fprintf('\nVisualizing Neural Network... \n')
% 
% displayData(Theta1(:, 2:end));
% 
% fprintf('\nProgram paused. Press enter to continue.\n');
% pause;

%% ================= Part 10: Implement Predict =================
%  After training the neural network, we would like to use it to predict
%  the labels. You will now implement the "predict" function to use the
%  neural network to predict the labels of the training set. This lets
%  you compute the training set accuracy.

pred = predict(Theta1, Theta2, X);
save('voicetrainfinal.mat','Theta1','Theta2');

disp('Trained successfully');
end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('voicetrainfinal.mat');
Fs=8000;
for l=1:20
 clear y1 y2 y3;
display('record voice');
pause();
x=wavrecord(Fs,Fs);
t=0.04;
j=1;
y1=0;
for i=1:8000
    if(abs(x(i))>t)
        y1(j)=x(i);
        j=j+1;
    end
end
y2=y1/(max(abs(y1)));
y3=[y2,zeros(1,3120-length(y2))];
y=filter([1 -0.9],1,y3');%high pass filter to boost the high frequency components
%%frame blocking
blocklen=240;%30ms block
overlap=80;
block(1,:)=y(1:240);
for i=1:18
    block(i+1,:)=y(i*160:(i*160+blocklen-1));
end
w=hamming(blocklen);
for i=1:19
    b=xcorr((block(i,:).*w'),12);%finding auto correlation from lag -12 to 12
    for j=1:12
        auto(j,:)=fliplr(b(j+1:j+12));%forming autocorrelation matrix from lag 0 to 11
    end
    z=fliplr(b(1:12));%forming a column matrix of autocorrelations for lags 1 to 12
    alpha=pinv(auto)*z';
    lpc(:,i)=alpha;
end
global a;
wavplay(x,Fs);
X1=reshape(lpc,1,228);
a1=sigmoid(Theta1*[1;X1']);
    h=sigmoid(Theta2*[1;a1]);
    m=max(h);
  p1=find(h==m);
  if(p1==10)
      P=0
      a.analogWrite(5,255);
      a.analogWrite(6,0);
      a.analogWrite(7,255);
      a.analogWrite(8,0);
  else
      P=p1 
      if(P==1)
          a.analogWrite(5,0);
      a.analogWrite(6,255);
      a.analogWrite(7,0);
      a.analogWrite(8,255);
      end
      if(P==2)
          a.analogWrite(5,255);
      a.analogWrite(6,0);
      a.analogWrite(7,0);
      a.analogWrite(8,0);
      end
      if(P==3)
          a.analogWrite(5,0);
      a.analogWrite(6,0);
      a.analogWrite(7,255);
      a.analogWrite(8,0);
      end
      if(P==4)
          a.analogWrite(5,0);
      a.analogWrite(6,0);
      a.analogWrite(7,0);
      a.analogWrite(8,0);
      end
      
          
  end
     
       
end
end

    
    
    

