%% Public Goods Game (PGG) Simulation
% Players decide whether to contribute (1) or not (0) to a common pool
% The total pool is multiplied and shared among neighbors

clear all; clc;

addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(100); % seed 

% --- PARAMETERS ---
numPlayers = 12;
actionsSpace = [0, 1];  % 0: Defect, 1: Cooperate
activationRate = 2;
cost = 1/2;  % cost c incurred by cooperators
benefit = 1; 

% Define activation distribution
pd = makedist('Exponential', 'mu', 1/activationRate); 
activationDistribution = @() random(pd);  

% --- NETWORK TOPOLOGY ---
p = 0.3; 
A = triu(rand(numPlayers) < p, 1);
adjacencyMatrix = A + A';

% --- GAME COMPONENTS ---
policy = bestResponse(); 
% policy = mistakeDynamic(0.2); 
% policy = learningDynamic(1, 1.01, true); 
playersArray = cell(1, numPlayers);

for i = 1:numPlayers
    initialAction = actionsSpace(randi(length(actionsSpace)));
    
    utilityFunction = @(profile) benefit * (dot(profile, adjacencyMatrix(i,:)) + profile(i) >= 1) - cost * profile(i);
    
    playersArray{i} = player(actionsSpace, initialAction, utilityFunction, ...
                             activationDistribution, policy); 
end 

% SIMULATION EXECUTION
gameManager = gameManager(playersArray, actionsSpace); 

horizon = 15; 
displayFlag = true; 

% Initialize Simulator
simulator = simulator(horizon, playersArray, displayFlag); 
simulator.agentSetUp(); 

% Run and Display Results
simulator.executeSimulation(); 
simulator.displayAgentStates();

% Interactive Network Visualization
gameManager.displayStats(adjacencyMatrix);