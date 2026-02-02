%% Coda MM1 con balking nella prima coda (come esempio lezione) 
clear all
clc

addpath(genpath('core'));
addpath(genpath('utils'));
addpath(genpath('implementations'));

rng(10);
arrivalRate = 1; 
serviceRate = 1.4; 

% GENERATOR 1 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDistribution = @(n) random(pd1); 
numType = 1; 
typeDistribution = @(n) 1; 
 
gen1 = generator(interArrivalDistribution, numType, typeDistribution); % 1 

% QUEUE 2 overtaking = 0; 
hardCapacity = 10; 
softCapacity = 6; 
softCapacityDistribution = @(n) randi([0,1]);
waitingFlag = false; 
overtakingFlag = false;

queue2 = balkingQueue(overtakingFlag , waitingFlag, hardCapacity, softCapacity, softCapacityDistribution); % 2 

% SERVER 3 
numServer = 1; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDistribution = @(n) random(pd2);  
revenueFunction = @(n) 0; 

server3 = classicServer(numServer,serverDistribution, revenueFunction);  % 3 

% SIMULAZIONE 

% vettore nodi, grafo struttura e orizzonte 
queueNodes = {gen1, queue2, server3}; 
queueGraph = [0, 1, 0; 0, 0, 1; 0, 0, 0]; 
horizon = 10150;  % per matchare con codice visto a lezione 
displayFlag = false; 


simulator = simulator(horizon,queueNodes,queueGraph, displayFlag); 
simulator.networkSetUp(); 
simulator.excuteSimulation(); 

statisticsArray = simulator.collectStatistics(); 
statisticsArrayWaiting = simulator.waitingTimeStatistic(); 


%simulator.clearSimulator(); 
%statisticsArray = simulator.collectStatistics();


