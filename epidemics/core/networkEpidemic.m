classdef networkEpidemic < handle
    % networkEpidemic: manager class for coordinating an epidemic simulation
    % orchestrates agent instantiation, state initialization, and topological 
    % mapping based on an adjacency matrix
    
    properties
        individualGraph % adjacency matrix (NxN) defining possible interaction
        individualsList % cell array containing all individual 
        numIndividuals % number of individuals in the population
        infectiousIndividualsList % indices of individual starting as Infected  
        recoveredIndividualsList % indices of individual starting as Recovered 
        trajectory 
    end
    
    methods
        function obj = networkEpidemic(individualGraph, numIndividuals, infectiousIndividuals, recoveredIndividuals)
            % constructor: initializes the social network 
            obj.individualGraph = individualGraph; 
            obj.numIndividuals = numIndividuals; 
            obj.individualsList = cell(1, obj.numIndividuals);
            obj.infectiousIndividualsList = infectiousIndividuals; 
            obj.recoveredIndividualsList = recoveredIndividuals; 
        end

        function individualsList = scenarioSetUp(obj, meetDistributionsArray, recoveryDistributionsArray, waningDistributionsArray)
            % scenarioSetUp: instantiates agents and assigns initial health states (S, I, or R)
            
            for i = 1:obj.numIndividuals
                % extract distributions for the current individual
                meetDistribution = meetDistributionsArray{i};
                recoveryDistribution = recoveryDistributionsArray{i};
                waningDistribution = waningDistributionsArray{i}; 

                if ismember(i, obj.infectiousIndividualsList)
                    initialState = individualState.Infected;
                elseif ismember(i, obj.recoveredIndividualsList)
                    initialState = individualState.Recovered;
                else
                    initialState = individualState.Susceptible;
                end 

                obj.individualsList{i} = individual(initialState, meetDistribution, ...
                    recoveryDistribution, waningDistribution); 
            end  
            individualsList = obj.individualsList; 
        end

        function networkSetUp(obj)
            % networkSetUp: maps the interaction network using the adjacency matrix
            for i = 1:obj.numIndividuals
                adjacentMask = (obj.individualGraph(i, :) == 1);
                neighbors = obj.individualsList(adjacentMask); 
                obj.individualsList{i}.neighborsAssignment(neighbors, obj); 
            end 
        end
    end 
end

