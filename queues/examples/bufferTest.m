%% TEST: Triple Queue Tandem Network with Buffering (Blocking-after-Service)
% Scenario: A chain of 3 servers where Server 3 and 5 are subject to blocking
% If Queue 4 or Queue 6 reaches capacity, the preceding server remains occupied
% (Waiting state) until a slot becomes available, preserving all customers

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

% --- QUEUE 1: Infinite Entry Buffer ---
overtakingFlag = true; 
waitingFlag = false; % No blocking possible at entry
capacity = inf; 
queue2 = classicQueue(overtakingFlag, waitingFlag, capacity);

% --- SERVER 1: Single Worker ---
serviceRate1 = 2; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate1);
serverDist1 = @() random(pd2);
server3 = classicServer(1, serverDist1);

% --- QUEUE 2: Critical Buffer ---
overtakingFlag = true; 
waitingFlag = true; % buffering enabled
capacity = 20; 
queue4 = classicQueue(overtakingFlag, waitingFlag, capacity);

% --- SERVER 2: Single Worker ---
serviceRate2 = 0.6;
pd3 = makedist('Exponential', 'mu', 1/serviceRate2);
serverDist2 = @() random(pd3);
server5 = classicServer(1, serverDist2);

% --- QUEUE 3: Final Buffer ---
overtaking = true; 
waitingFlag = true; % buffering enabled
capacity = 5; 
queue6 = classicQueue(overtaking, waitingFlag, capacity);

% --- SERVER 3: Single Worker ---
numWorkers = 1; 
serviceRate3 = 0.3; 
pd4 = makedist('Exponential', 'mu', 1/serviceRate3);
serverDist3 = @() random(pd4);  
server7 = classicServer(numWorkers, serverDist3);

% 2. NETWORK TOPOLOGY SETUP
% Path: Gen(1) -> Q(2) -> S(3) -> Q(4) -> S(5) -> Q(6) -> S(7)
queueNodes = {gen1, queue2, server3, queue4, server5, queue6, server7}; 
queueGraph = [0, 1, 0, 0, 0, 0, 0; 
              0, 0, 1, 0, 0, 0, 0; 
              0, 0, 0, 1, 0, 0, 0; 
              0, 0, 0, 0, 1, 0, 0; 
              0, 0, 0, 0, 0, 1, 0; 
              0, 0, 0, 0, 0, 0, 1; 
              0, 0, 0, 0, 0, 0, 0]; 

network = networkQueue(queueNodes, queueGraph); 
network.networkSetUp(); 

% SIMULATION EXECUTION
horizon = 10; 
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


