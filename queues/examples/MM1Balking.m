%% TEST: M/M/1 Balking Queue System
% Scenario: Single Server with a finite buffer divided into two zones:
% 1. Stable Zone: Entry is guaranteed (length < softCapacity).
% 2. Balking Zone: Entry depends on a probability (soft <= length < hard).
% 3. Full Zone: Entry is impossible (length >= hardCapacity).

clear all; clc;
addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 

% --- GENERATOR 1: Standard Arrivals ---
arrivalRate = 3; 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDist = @() random(pd1);
numType = 1; 
typeDist = @() 1; 

gen1 = generator(interArrivalDist, numType, typeDist);

% --- QUEUE 2: Balking Buffer ---
hardCapacity = 10;   % absolute physical limit
softCapacity = 6;    % threshold where customers start to lose interest
balkingProb = 0.5; % balking probability: e.g., 50% chance to join if queue > softCapacity
softCapacityDist = @() (rand() > balkingProb); 

waitingFlag = false; 
overtakingFlag = false;
queue2 = balkingQueue(overtakingFlag, waitingFlag, hardCapacity, softCapacity, softCapacityDist);

% --- SERVER 3: Single Worker ---
serviceRate = 0.8; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDist = @() random(pd2);
server3 = classicServer(1, serverDist);

% NETWORK TOPOLOGY SETUP
% Path: Gen (1) -> Balking Queue (2) -> Server (3)
queueNodes = {gen1, queue2, server3}; 
queueGraph = [0, 1, 0; 
              0, 0, 1; 
              0, 0, 0]; 

network = networkQueue(queueNodes, queueGraph); 
network.networkSetUp(); 

% SIMULATION EXECUTION
horizon = 100; 
displayFlag = true; 

% Initialize Simulator
sim = simulator(horizon, queueNodes, displayFlag); 
sim.agentSetUp(); 

% Run and Display Results
sim.executeSimulation(); 
sim.displayAgentStates();

% Post-Simulation Statistics
fprintf('\n>>> NETWORK PERFORMANCE ANALYSIS <<<\n');
network.statistic();




