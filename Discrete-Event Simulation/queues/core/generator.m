classdef generator < handle 
    % generator: Handles entity creation for the simulation network
    % Generates customers with stochastic inter-arrival times and 
    % assigns categorized types before pushing them to a destination queue

    properties
        id % entity identifier 
        simulationId % identifier in simulator
        clock % local node clock 
        interArrivalDistribution % inter-arrival times distribution
        destinationQueue % destination queue (one)  
        customerGenerated % buffer for the current customer 
        networkLength % number of nodes (for customer data allocation)
        numType % number of customer types (in simulation)
        typeDistribution  % customer type distribution  
        count % total generated customers 
        countPerType % array tracking generation per type  
    end
    
    methods
        function obj = generator(interArrivalDistribution, numType, typeDistribution) 
            % constructor: initializes generation distributions and counters
            obj.id = nodeIdGenerator.getId(); 
            obj.clock = 0; 
            obj.customerGenerated = [];
 
            obj.interArrivalDistribution = interArrivalDistribution; 
            obj.numType = numType; 
            obj.typeDistribution = typeDistribution;
            
            obj.count = 0; 
            obj.countPerType = zeros(1, numType);  
        end

        % Network Topology Setup
        function destinationQueueAssignment(obj, destinationQueue, networkLength)
            obj.networkLength = networkLength; 
            obj.destinationQueue = destinationQueue;
        end

        function initialize(obj, eventsList, displayFlag)    
            % initialize: starts the generation process by scheduling the first arrival
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[GEN    %-3d] TYPE: Customer Generator\n', obj.simulationId);
                fprintf('              ID: %d\n', obj.id);
                fprintf('              CUSTOMER TYPES: %d\n', obj.numType);
                
                if ~isempty(obj.destinationQueue)
                    fprintf('              DESTINATION QUEUE: %d\n', obj.destinationQueue.id);
                else
                    fprintf('              DESTINATION QUEUE: Warning (Not Assigned)\n');
                end
                
                fprintf('————————————————————————————————————————————————————————————\n');
            end
            obj.handleArrival(eventsList); 
        end
        
        function execute(obj, externalClock, eventsList, displayFlag)
            % execute: main event cycle (process current customer and schedule next)
            obj.handleExit(externalClock, displayFlag);
            obj.handleArrival(eventsList); 
        end

        function updateFlag = update(obj, ~, ~, ~)
            % update: placeholder for external event synchronization
            updateFlag = false; 
        end 

        function handleArrival(obj, eventsList)
            % handleArrival: samples inter-arrival time and creates a new customer object
            interArrival = obj.interArrivalDistribution(); 
            obj.clock = obj.clock + interArrival;  
            eventsList.update(obj.simulationId, obj.clock);

            % create and categorize new customer 
            type = obj.typeDistribution();
            obj.customerGenerated = customer(type, obj.clock, obj.networkLength); 
            obj.customerGenerated.path(end + 1) = obj.id; 
            obj.customerGenerated.startTime(obj.id) = obj.clock; 

            % stats update   
            obj.count = obj.count + 1; 
            obj.countPerType(type) = obj.countPerType(type) + 1; 
        end
       
        function handleExit(obj, externalClock, displayFlag)
            % handleExit: hands off the generated customer to the destination queue
            if displayFlag
                fprintf('[GEN %d] Customer %d Generated (Clock: %.2f)\n', ...
                    obj.simulationId, obj.customerGenerated.id, externalClock);
            end

            exitCustomer = obj.customerGenerated;
            obj.customerGenerated = []; % clear buffer
            exitCustomer.endTime(obj.id) = obj.clock;

            obj.destinationQueue.handleArrival(exitCustomer, externalClock, displayFlag); % push to destination node 
        end

       function displayAgentState(obj, externalClock)
            % displayAgentState: Prints a summary of production results and type breakdown
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[GEN    %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d | TOTAL GENERATED: %d\n', obj.id, obj.count);
            
            if obj.count > 0
                fprintf('              GENERATION BREAKDOWN:\n');
                for i = 1:obj.numType
                    qty = obj.countPerType(i);
                    perc = (qty / obj.count) * 100;
                    fprintf('                • Type %-2d: %4d (%5.1f%%)\n', i, qty, perc);
                end
            end
            fprintf('————————————————————————————————————————————————————————————\n');
        end
        
        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = 0; 
            obj.customerGenerated = [];
            obj.count = 0;
            obj.countPerType = zeros(1, obj.numType);
        end
    end
end