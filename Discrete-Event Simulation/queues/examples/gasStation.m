%% SCENARIO: Gas Station with Physical Constraints and Buffering
% This script simulates a service station where:
% 1. A generator creates two types of customers (e.g., Gasoline vs Diesel)
% 2. Entry Queue: Limited buffer for cars entering the station
% 3. Line Flow Server: Pumps arranged in rows where a car at a rear pump 
%    blocks the exit of the car at the front pump
% 4. Buffering Queue: A waiting area before the payment kiosks
% 5. Payment Kiosks: Final service point (potential bottleneck) 

clc; clear all;

addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 

% --- GENERATOR: Customer Arrivals ---
arrivalRate = 5; 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDistribution1 = @() random(pd1);
numType = 2; 
typeDistribution1 = @() randi([1,2]); % uniform distribution between Type 1 and 2
gen1 = generator(interArrivalDistribution1, numType, typeDistribution1);

% --- QUEUE 2: Entry Buffer ---
capacity = 10; 
overtakingFlag = false; % FIFO: No overtaking allowed
waitingFlag = false;    % Loss system: If full, customers are rejected
queue2 = classicQueue(overtakingFlag, waitingFlag, capacity);

% --- SERVER 3: Gas Pumps (Line Flow) ---
serviceRate = 1; 
numWorker = 4; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDistribution = @() random(pd2);   

% Physical Constraints Matrix (Adjacency Matrix)
% A(i,j) = 1 means Worker i blocks Worker j's exit path
% Layout: [Pump 1 -> Pump 2] and [Pump 3 -> Pump 4]
constraintsMatrix = [0, 0, 0, 0;  % Pump 1 blocks entry to Pump 2
                     1, 0, 0, 0;  % Pump 2 blocks exit from Pump 2
                     0, 0, 0, 0;  % Pump 3 blocks entry to Pump 4
                     0, 0, 1, 0]; % Pump 4 blocks exit from Pump 3

% Worker Specialization: Pumps 1&2 for Type 1, Pumps 3&4 for Type 2
typesPerWorker = {1, 1, 2, 2}; 
server3 = lineFlowServer(numWorker, serverDistribution, constraintsMatrix, numType, typesPerWorker);

% --- QUEUE 4: Payment Buffer ---
capacity = 5; 
overtakingFlag = false; 
waitingFlag = true; 
queue4 = classicQueue(overtakingFlag, waitingFlag, capacity);

% --- SERVER 5: Payment Kiosks (Classic) ---
serviceRate = 0.5; 
numWorker = 2; 
pd3 = makedist('Exponential', 'mu', 1/serviceRate);
paymentDist = @() random(pd3);  
server5 = classicServer(numWorker, paymentDist);

% 2. NETWORK TOPOLOGY SETUP
% Connections: Gen -> Q2 -> S3 -> Q4 -> S5
queueNodes = {gen1, queue2, server3, queue4, server5}; 
queueGraph = [0, 1, 0, 0, 0; 
              0, 0, 1, 0, 0; 
              0, 0, 0, 1, 0; 
              0, 0, 0, 0, 1; 
              0, 0, 0, 0, 0];

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



