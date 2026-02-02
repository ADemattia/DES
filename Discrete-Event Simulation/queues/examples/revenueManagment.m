%% TEST: Revenue Management with Littlewood's Protection Level
% Scenario: Two customer classes (High-Price vs. Low-Price).
% Goal: Maximize revenue by protecting seats for late-arriving Class 1 customers
% using a protection level calculated via Poisson distribution.

clc; clear all;

addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')
rng(10); 

% ECONOMIC PARAMETER 
T = 60;  % Horizon
price1 = 400; % High-class ticket price
price2 = 200; % Low-class ticket price

% Arrival rates (True vs Estimated for the rule)
trueArrivalRate1 = 0.4; 
trueArrivalRate2 = 2.2;
hatArrivalRate1 = 0.5;  % expected demand for Class 1

% Littlewood's Rule: Protection Level (y)
protectionLevel = poissinv(1 - price2/price1, hatArrivalRate1 * T);


% --- GENERATOR 1: High-Price Customers (Type 1) ---
pd1 = makedist('Exponential', 'mu', 1/trueArrivalRate1);
interArrivalDist1 = @() random(pd1);
numType = 2; 
typeDist1 = @() 1; 
gen1 = generator(interArrivalDist1, numType, typeDist1);

% --- GENERATOR 2: Low-Price Customers (Type 2) ---
pd2 = makedist('Exponential', 'mu', 1/trueArrivalRate2);
interArrivalDist2 = @() random(pd2);
typeDist2 = @() 2; 
gen2 = generator(interArrivalDist2, numType, typeDist2);

% --- QUEUE 3: Infinite Buffer (Booking Request Pool) ---
capacityPool = inf; 
overtaking = true; 
waitingFlag = false; 
queue3 = classicQueue(overtaking, waitingFlag, capacityPool);

% --- SERVER 4: Priority Service (Booking Engine) ---
totalCapacity = 100; % total seats available
numWorkers = 1; % single transaction processor
serviceDist = @() 0; % instant booking (no service time delay)

% Revenue Function: Maps customer type to price
revenueVector = [price1, price2];
revenueFunction = @(type) revenueVector(type);

% Booking Limits: Class 1 can access all seats, 
% Class 2 is limited to (Total - Protected)
maxCapacityPerType = [totalCapacity, totalCapacity - protectionLevel]; 

server4 = priorityServer(numWorkers, serviceDist, totalCapacity, numType, ...
                         maxCapacityPerType, revenueFunction);

% NETWORK TOPOLOGY SETUP
% Path: [Gen1, Gen2] -> Queue3 -> Server4
queueNodes = {gen1, gen2, queue3, server4};
queueGraph = [0, 0, 1, 0; 
              0, 0, 1, 0; 
              0, 0, 0, 1; 
              0, 0, 0, 0];

network = networkQueue(queueNodes, queueGraph); 
network.networkSetUp();

% SIMULATION EXECUTION
horizon = T; 
displayFlag = true; 

% Initialize Simulator
sim = simulator(horizon, queueNodes, displayFlag); 
sim.agentSetUp(); 

% Run and Display Results
sim.executeSimulation(); 
sim.displayAgentStates();

% Post-Simulation Statistics
fprintf('\n>>> REVENUE PERFORMANCE ANALYSIS <<<\n');
network.statistic();


