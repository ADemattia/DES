%% TEST: SIRS Epidemic Model on Discrete Network
% SIRS Model: Individuals transition S -> I -> R -> S
% Immunity is temporary; after the waning period, Recovered (R) agents 
% become Susceptible (S) again, allowing for potential re-infection

clc; clear all;

addpath('../core')
addpath('../utils')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 

% --- PARAMETERS ---
rateRecov = 0.01;   
rateWane = 0.1;     
rateLink = 2;       
numIndividuals = 5; 

% Social network adjacency matrix
individualGraph = [0 1 0 0 1;
                   1 0 1 0 0;
                   0 1 0 1 0;
                   0 0 1 0 1;
                   1 0 0 1 0];

% Initial epidemic states
infectiousIndividuals = 1; 
recoveredIndividuals = [];  

meetDistributionsArray = cell(1, numIndividuals);
recoveryDistributionsArray = cell(1, numIndividuals);
waningDistributionsArray = cell(1, numIndividuals);

for i = 1:numIndividuals
    % contact distribution: exponential based on link presence
    meetDistributionsArray{i} = @(neighborId) random(makedist('Exponential', 'mu', ...
        1/(rateLink * individualGraph(i, neighborId))));
    
    % recovery distribution: time until an infected agent clears the virus
    pdRecov = makedist('Exponential', 'mu', 1/rateRecov);
    recoveryDistributionsArray{i} = @() random(pdRecov);  
    
    % temporary immunity, after this time the individual becomes Susceptible again
    pdWane = makedist('Exponential', 'mu', 1/rateWane);
    waningDistributionsArray{i} = @() random(pdWane); 
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