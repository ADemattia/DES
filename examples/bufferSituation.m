%% Tripla coda, ultime due hanno buffering (i.e. server aspetta che coda si liberi per rilasciare customer) 
% La condizione di buffering è data in waitingFlag
clear all
clc 

addpath(genpath('core'));
addpath(genpath('utils'));
addpath(genpath('implementations'));

rng(10)

% GENERATOR 1 

arrivalRate = 1; 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDistribution = @(n) random(pd1); 
numType = 1; 
typeDistribution = @(n) 1; 

gen1 = generator(interArrivalDistribution, numType, typeDistribution); % 1 

% QUEUE 2 
overtakingFlag = true; 
waitingFlag = false; % no buffering 
capacity = inf; % capacità infinita

queue2 = classicQueue(overtakingFlag, waitingFlag, capacity); % 2 

% SERVER 3 

numServer = 1; 
serviceRate1 = 3;
pd2 = makedist('Exponential', 'mu', 1/serviceRate1);
serverDistribution = @(n) random(pd2);
revenueFunction = @(n) 0; 

server3 = classicServer(numServer,serverDistribution,revenueFunction); % 3 

% QUEUE 4

overtakingFlag = true; 
waitingFlag = true; % buffering  
capacity = 1; 

queue4 = classicQueue(overtakingFlag, waitingFlag, capacity); % 4 

% SERVER 5

numServer = 1;
serviceRate2 = 0.6;
pd3 = makedist('Exponential', 'mu', 1/serviceRate2);
serverDistribution = @(n) random(pd3);  
revenueFunction = @(n) 0; 

server5 = classicServer(numServer,serverDistribution,revenueFunction); % 5

% QUEUE 6 

overtaking = 1; 
waitingFlag = true; % buffering 
capacity = 5; 

queue6 = classicQueue(overtaking, waitingFlag, capacity); % 6 

% SERVER 7

numServer = 1; 
serviceRate3 = 0.1; 
pd4 = makedist('Exponential', 'mu', 1/serviceRate3);
serverDistribution = @(n) random(pd4);  
revenueFunction = @(n) 0; 

server7 = classicServer(numServer,serverDistribution,revenueFunction); % 7

% SIMULAZIONE 
% vettore nodi, grafo struttura e orizzonte 
queueNodes = {gen1, queue2, server3, queue4, server5, queue6, server7}; 
queueGraph = [0, 1, 0, 0, 0, 0, 0; 0, 0, 1, 0, 0, 0, 0; 0, 0, 0, 1, 0, 0, 0; 0, 0, 0, 0, 1, 0, 0; 0, 0, 0, 0, 0, 1, 0; 0, 0, 0, 0, 0, 0, 1; 0, 0, 0, 0, 0, 0, 0]; 
horizon = 30; 
displayFlag = false; 

simulator = simulator(horizon,queueNodes,queueGraph, displayFlag); 
simulator.networkSetUp(); 
simulator.excuteSimulation();

statisticsArray = simulator.collectStatistics(); 
statisticsArrayWaiting = simulator.waitingTimeStatistic(); 

%simulator.clearSimulator(); 
%statisticsArray = simulator.collectStatistics();


