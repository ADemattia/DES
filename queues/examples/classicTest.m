%% TEST: Classic M/M/1 Queueing System
% Scenario: Single Generator, Infinite Capacity Queue, and Single Server

clear all; clc;
addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 


% --- GENERATOR 1 ---
arrivalRate = 3; 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDist = @() random(pd1);
numType = 1; 
typeDist = @() 1; 

gen1 = generator(interArrivalDist, numType, typeDist);

% --- QUEUE 2 - Infinite Buffer (M/M/1) ---
overtaking = false; 
capacity = inf;     % infinite capacity 
waitingFlag = false; % not applicable for infinite capacity
queue2 = classicQueue(overtaking, waitingFlag, capacity);

% --- SERVER 3 - Single Worker ---
numServer = 1; 
serviceRate = 3;    % Service is slower than arrivals (Unstable system)
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDist = @() random(pd2);  
server3 = classicServer(numServer, serverDist);

% NETWORK TOPOLOGY SETUP
% Path: Generator (1) -> Queue (2) -> Server (3)
queueNodes = {gen1, queue2, server3}; 
queueGraph = [0, 1, 0; 
              0, 0, 1; 
              0, 0, 0]; 

network = networkQueue(queueNodes, queueGraph); 
network.networkSetUp(); 

% SIMULATION EXECUTION
horizon = 1e2; 
displayFlag = true; 

% Initialize Simulator
sim = simulator(horizon, queueNodes, displayFlag); 
sim.agentSetUp(); 

% Run and Display Results
sim.executeSimulation(); 
sim.displayAgentStates();

% Post-Simulation Statistics
fprintf('\n>>> FINAL NETWORK PERFORMANCE <<<\n');
network.statistic();
