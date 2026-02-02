%% TEST: SI Epidemic Model on Discrete Network
% SI Model: Individuals transition from Susceptible (S) to Infectious (I).
% In this variant, there is no recovery (R); once infected, agents remain 
% infectious indefinitely. 

clc; clear all;


addpath('../core')
addpath('../utils')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 

% --- PARAMETERS ---
rateLink = 2;
numIndividuals = 5; 

% Social network adjacency matrix (Ring topology)
individualGraph = [0 1 0 0 1;
                   1 0 1 0 0;
                   0 1 0 1 0;
                   0 0 1 0 1;
                   1 0 0 1 0];

% Initial epidemic states
infectiousIndividuals = 1; % patient zero
recoveredIndividuals = [];  

meetDistributionsArray = cell(1, numIndividuals);
recoveryDistributionsArray = cell(1, numIndividuals);
waningDistributionsArray = cell(1, numIndividuals);

for i = 1:numIndividuals
    % contact distribution: exponential based on link presence
    meetDistributionsArray{i} = @(neighborId) random(makedist('Exponential', 'mu', ...
        1/(rateLink * individualGraph(i, neighborId))));
    
    % recovery time is set to infinity, since agents never recover
    recoveryDistributionsArray{i} = @() inf;  
    
    waningDistributionsArray{i} = @() inf; 
end

% SIMULATION EXECUTION
network = networkEpidemic(individualGraph, numIndividuals, infectiousIndividuals, recoveredIndividuals); 
individualArray = network.scenarioSetUp(meetDistributionsArray, recoveryDistributionsArray, waningDistributionsArray); 
network.networkSetUp();

horizon = 10; 
displayFlag = true; 

% Initialize Simulator
simulator = simulator(horizon, individualArray, displayFlag); 
simulator.agentSetUp(); 

% Run and Display Results
simulator.executeSimulation(); 
simulator.displayAgentStates();