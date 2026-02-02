%% Majority Game Simulation
% In this game, players gain utility by coordinating their actions with 
% their neighbors in the social network (Adjacency Matrix)
% Players maximize payoff by choosing an action that matches the majority of neighbors

clear all; clc;
addpath('../core')
addpath('../utils')
addpath('../implementations')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed

% --- PARAMETERS & DISTRIBUTIONS ---
numPlayers = 10;      
activationRate = 2;  
actionsSpace = [-1, 1]; 

pd = makedist('Exponential', 'mu', 1/activationRate); 
activationDistribution = @() random(pd);  

% --- NETWORK TOPOLOGY ---
p = 0.4; % Connection probability
A = rand(numPlayers) < p;
A = triu(A, 1);
adjacencyMatrix = A + A'; % Symmetric matrix 

policy = bestResponse(); 
playersArray = cell(1, numPlayers);

for i = 1:numPlayers
    % randomly assign initial strategy from the actions space
    initialAction = actionsSpace(randi(length(actionsSpace)));  
    
    % utility Function: U_i = a_i * sum(w_ij * a_j)
    utilityFunction = @(profile) profile(i) * dot(profile, adjacencyMatrix(i,:)); 
    
    playersArray{i} = player(actionsSpace, initialAction, utilityFunction, ...
                             activationDistribution, policy); 
end 

% SIMULATION EXECUTION
gameManager = gameManager(playersArray, actionsSpace); 

horizon = 10;       
displayFlag = true; 

% Initialize Simulator
simulator = simulator(horizon, playersArray, displayFlag); 
simulator.agentSetUp(); 

% Run and Display Results
simulator.executeSimulation(); 
simulator.displayAgentStates();

% Interactive Network Visualization
gameManager.displayStats(adjacencyMatrix);