classdef (Abstract) queue < handle
    % queue: Abstract class for a network node that manages customer waiting lines
    % handles arrival/departure logic, statistical tracking, and network connectivity
    
    properties
        id % entity identifier 
        simulationId % identifier in simulator
        clock % local node clock
        previousEventClock % reference timestamp for time-weighted statistics
        sourceServers % source Servers (zero, one or more)
        sourceGenerators % source Generator (zero, one or more)
        destinationServer % destination Server (one)
        customersList  % current list of customers in queue
        lengthQueue  % current number of customers in line
        
        overtakingFlag % boolean: allows customers to bypass others in service
        waitingFlag % boolean: true = blocking (server waits), false = loss (customer leaves) 
              
        count  % total customers entered the queue (lost customers not counted) 
        averageLength % time-weighted average queue length
        lostCustomers  % total customers rejected due to capacity limits
    end
    
    methods
        function obj = queue(overtakingFlag, waitingFlag) 
            % constructor: initializes capacity, flag and counters
            obj.id = nodeIdGenerator.getId();  
            obj.clock = inf; 
            obj.previousEventClock = 0; 
            obj.customersList = customer.empty(); 
            obj.overtakingFlag = overtakingFlag; 
            obj.waitingFlag = waitingFlag; 

            % stats initialization
            obj.lengthQueue = 0; 
            obj.count = 0; 
            obj.averageLength = 0; 
            obj.lostCustomers = 0; 
        end
        
        % Network Topology Setup
        function destinationServerAssignment(obj, destinationServer)
            obj.destinationServer = destinationServer;
        end

        function sourceServersAssignment(obj, sourceServers)
            obj.sourceServers = sourceServers;
        end

        function sourceGeneratorsAssignment(obj, sourcesGenerators)
            obj.sourceGenerators = sourcesGenerators;
        end
       
        function updateFlag = update(obj, externalClock, eventsList, displayFlag)
            % update: synchronizes the queue state by pushing customers forward or pulling from sources
            updateFlag = false; 

             % try to move customers from this queue to the destination server
            [canServe, selectedCustomer, selectedWorker, selectedQueue] = obj.destinationServer.checkArrival(); 
            while canServe && selectedQueue.id == obj.id 
                updateFlag = true;  
                obj.destinationServer.handleArrival(selectedCustomer, selectedWorker, selectedQueue, externalClock, eventsList, displayFlag);
                [canServe, selectedCustomer, selectedWorker, selectedQueue] = obj.destinationServer.checkArrival(); 
            end

             % pull customers from blocked source servers if space is now available
             for i = 1:length(obj.sourceServers) 
                 while obj.sourceServers{i}.checkExit()
                     updateFlag = true;  
                     obj.sourceServers{i}.handleExit(externalClock, eventsList, displayFlag);
                 end
             end
        end 

        function handleExit(obj, customer, externalClock, displayFlag)
            % handleExit: removes a customer from the queue and updates internal stats
            
            if displayFlag
                fprintf('[QUEUE %d] Customer %d DEPARTURE (Clock: %.2f)\n', ...
                    obj.simulationId, customer.id, externalClock);
            end

            
            % update stats and remove from list
            customer.endTime(obj.id) = externalClock;
            obj.updateStat(externalClock);
            pos = find(obj.customersList == customer, 1); 
            obj.customersList(pos) = [];
            obj.lengthQueue = obj.lengthQueue - 1;
        end 
        
        function updateStat(obj, externalClock)
            % updateStat: calculates time-weighted average queue length
            clockDiff = externalClock - obj.previousEventClock;   
            totalLength = obj.averageLength * obj.previousEventClock + clockDiff * obj.lengthQueue;
            obj.averageLength = totalLength/externalClock;
            obj.previousEventClock = externalClock;  
        end

        function displayAgentState(obj, externalClock)
            % displayAgentState: prints final queue statistics in a formatted block
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[QUEUE  %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d\n', obj.id);
            fprintf('              THROUGHPUT:       %d customers\n', obj.count);
            fprintf('              LOST CUSTOMERS:   %d\n', obj.lostCustomers);
            fprintf('              CURRENT LENGTH:   %d\n', obj.lengthQueue);
            fprintf('              AVG QUEUE LENGTH: %.2f\n', obj.averageLength);
            fprintf('————————————————————————————————————————————————————————————\n');
        end
    end
    methods (Abstract)
        % initialize:  prepare the queue for the simulation
        initialize(obj, eventsList, displayFlag)

        % handleArrival: places the customer in the queue
        handleArrival(obj, customer, externalClock, displayFlag)

        % checkArrival: determine if a new customer can enter the queue
        canEnter = checkArrival(obj)  

        % clear: reset statistics and states for a new simulation run
        clear(obj)
    end
end