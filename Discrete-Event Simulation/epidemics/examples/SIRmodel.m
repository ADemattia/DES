%% TEST: SIR Epidemic Model on Discrete Network
% SIR Model: Individuals transition from Susceptible (S) to Infectious (I) 
% via contact, and then to Recovered (R) with permanent immunity
% Transmission is constrained by the network adjacency matrix

clc; clear all;

addpath('../core')
addpath('../utils')
addpath('../../simulation/core')
addpath('../../simulation/utils')

rng(10); % seed 

% --- PARAMETERS ---
rateRecov = 1;
rateLink = 2;
numIndividuals = 5;

% Social network adjacency matrix
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
    pdLink = makedist('Exponential', 'mu', 1/rateLink);  
    meetDistributionsArray{i} = @(neighborId) random(makedist('Exponential', 'mu', ...
        1/(rateLink * individualGraph(i, neighborId))));

    % recovery distribution: time until an infected agent clears the virus
    pdRecov = makedist('Exponential', 'mu', 1/rateRecov);   
    recoveryDistributionsArray{i} = @() random(pdRecov);  
    
    % immunity waning: set to infinity for permanent recovery (SIR)
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


