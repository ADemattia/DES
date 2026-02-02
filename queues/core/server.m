classdef (Abstract) server < handle
    % server: Abstract base class representing a service node with multiple workers
    % It manages service distributions, worker states, and coordinates the 
    % transition of customers between source and destination queues
    
    properties
        id % entity identifier
        simulationId % identifier in simulator 
        clock % local node clock 
         
        destinationQueue  % destination Queue (one)
        sourceQueues  % source Queues (one or more) 
        numSourceQueues % num source Queues 
       
        numWorkers % total number of workers in this server
        workersArray % cell array of workers object 
        availableWorkers % binary array tracking current availability (1 = idle, 0 = busy)  
        serverDistribution % service time distribution  
        workerEvent % handle to the worker object triggering the next event 
        
        waitingList % list of workers waiting to release finished customers  
        count % total customers served
    end
    
    methods
        function obj = server(numWorkers, serverDistribution)
            % constructor: initializes default properties and instantiates workers
            obj.id = nodeIdGenerator.getId();
            obj.simulationId = 0; 
            obj.clock = inf; 
            obj.workerEvent = worker(); 
            obj.waitingList = worker.empty();
            obj.count = 0; 

            obj.serverDistribution = serverDistribution;
            obj.numWorkers = numWorkers;  
            obj.availableWorkers = ones(1, numWorkers); 
            obj.workersArray = cell(1, numWorkers);
            for i=1:numWorkers
                obj.workersArray{i} = worker(i, serverDistribution); 
            end  
        end
        
        % Network Topology  
        function destinationQueueAssignment(obj, destinationQueue)
            obj.destinationQueue = destinationQueue; 
        end

        function sourceQueuesAssignment(obj, sourceQueues)
            obj.sourceQueues = sourceQueues; 
            obj.numSourceQueues = length(obj.sourceQueues); 
        end

        function updateClock(obj, eventsList)
            % updateClock: synchronizes server clock with the earliest worker completion
            obj.workerEvent = worker();                    
            workerClocks = cellfun(@(w) w.clock, obj.workersArray); 
            [obj.clock, idWorker] = min(workerClocks);     

            % identify the specific worker triggering the next event
            obj.workerEvent = obj.workersArray{idWorker};  
            eventsList.update(obj.simulationId, obj.clock); 
        end

        function execute(obj, externalClock, eventsList, displayFlag)
            % execute: handles service completion and attempts customer release

            % move worker to waiting state (blocked-after-service)
            obj.handleWaiting(externalClock, eventsList, displayFlag);

            % release customers downstream while capacity exists
            while obj.checkExit()
                obj.handleExit(externalClock, eventsList, displayFlag);
            end
        end

        function updateFlag = update(obj, externalClock, eventsList, displayFlag)
            % update: propagates state changes
            updateFlag = false; 

            % process exits for workers previously blocked
            while obj.checkExit()
                updateFlag = true; 
                obj.handleExit(externalClock, eventsList, displayFlag);
            end 

            % attempt to start new services from source queues
            [canServe, selectedCustomer, selectedWorker, selectedQueue] = obj.checkArrival();  
            while canServe 
                updateFlag = true;
                obj.handleArrival(selectedCustomer, selectedWorker, selectedQueue, externalClock, eventsList, displayFlag);
                [canServe, selectedCustomer, selectedWorker, selectedQueue] = obj.checkArrival();
            end
        end 
    end 

    methods (Abstract)
        % initialize: prepare the server for the simulation
        initialize(obj, eventsList, displayFlag) 
        
        % checkArrival: determine if a new customer can enter service
        [canServe, selectedCustomer, assignedWorker, selectedQueue] = checkArrival(obj); 
        
        % handleArrival: start service and schedule completion time
        handleArrival(obj, customer, worker, queue, externalClock, eventsList, displayFlag); 
        
        % checkExit: check if a finished customer can move to the next queue
        canExit = checkExit(obj); 
        
        % handleWaiting: move a customer/worker to the waiting list after service completion
        handleWaiting(obj, externalClock, eventsList, displayFlag); 
        
        % handleExit: Formally release customer and return worker to idle state
        handleExit(obj, externalClock, eventsList, displayFlag); 
        
        % clear: reset statistics and states for a new simulation run
        clear(obj);
    end
end

