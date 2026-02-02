%% REVENUE MANAGMENT con due classi di prezzo e un livello di protezione dato dalla regola di Littlewood 
clc
clear all

addpath(genpath('core'));
addpath(genpath('utils'));
addpath(genpath('implementations'));

rng(10); 

% dati iniziali 
T = 60;
price1 = 400;
price2 = 200;
trueArrivalRate1 = 0.4; 
trueArrivalRate2 = 2.2;
hatArrivalRate1 = 0.5;
hatArrivalRate2 = 2;
protectionLevel = poissinv(1-price2/price1, hatArrivalRate1*T);

% GENERATOR 1 

pd1 = makedist('Exponential', 'mu', 1/trueArrivalRate1);
interArrivalDistribution1 = @(n) random(pd1);
numType = 2; % numero tipi in sistema 
typeDistribution1 = @(n) 1;

gen1 = generator(interArrivalDistribution1, numType, typeDistribution1); % 1 

% GENERATOR 2 

pd2 = makedist('Exponential', 'mu', 1/trueArrivalRate2);
interArrivalDistribution2 = @(n) random(pd2);
numType = 2; % numero tipi in sistema  
typeDistribution2 = @(n) 2; 
gen2 = generator(interArrivalDistribution2, numType, typeDistribution2); % 2 

% QUEUE 3 

capacity = inf; 
overtaking = 1; 
waitingFlag = false; % customer non aspetta, entra subito sempre 

queue = classicQueue(overtaking, waitingFlag, capacity); % 3 

% SERVER 4

numServer = 1; 
serverDistribution = @(n) 0;
revenueFunction = @(n) (n == 1)*price1 + (n == 2)*price2;
capacity = 100;
numType = 2; 
priorityArray = [capacity, capacity-protectionLevel]; % disponibilità massime per ogni classe 

server = priorityServer(numServer,serverDistribution, revenueFunction,capacity,numType, priorityArray); % 4 

% SIMULAZIONE 

% vettore nodi, grafo struttura e orizzonte 
queueNodes = {gen1, gen2, queue, server};
queueGraph = [0, 0, 1, 0; 0, 0, 1, 0; 0, 0, 0, 1; 0, 0, 0, 0]; 
horizon = T; 
displayFlag = false; 

simulator = simulator(horizon,queueNodes,queueGraph, displayFlag); 
simulator.networkSetUp(); 
simulator.excuteSimulation();

statisticsArray = simulator.collectStatistics(); 
statisticsArrayWaiting = simulator.waitingTimeStatistic(); 
 
%simulator.clearSimulator(); 
%statisticsArray = simulator.collectStatistics();


% attenzione conta per i generatori anche i customer che devono essere
% indirizzati e per il server i customer in lavorazione 