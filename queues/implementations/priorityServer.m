classdef priorityServer < server
    % priorityServer: models a server with finite total service capacity
    % and specific sub-quotas per customer type (e.g., booking systems)
    % includes revenue tracking based on customer types

    properties       
        capacity % total service capacity 
        occupiedSeat % current number of occupied seats
        numType % total number of customer categories
        maxCapacityPerType  % array defining max seats available for each type 
        countPerType % counter for customers served per category (not lost) 
        revenueDistribution % function for type-based revenue
        revenue % total revenue 
    end
    
    methods
        function  obj = priorityServer(numWorker, serverDistribution, capacity, numType, maxCapacityPerType, revenueDistribution)
            % constructor: initializes capacity limits and revenue tracking
            obj@server(numWorker, serverDistribution); 
            obj.capacity = capacity; 
            obj.occupiedSeat = 0; 
            obj.numType = numType; 
            obj.countPerType = zeros(1, obj.numType);
            obj.revenueDistribution = revenueDistribution; 
            obj.revenue = 0; 
            obj.maxCapacityPerType = maxCapacityPerType; 
        end
        
        function initialize(obj, ~, displayFlag) 
            % prints its configuration setup
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[SERVER %-3d] TYPE: Priority Server (Booking/Capacity)\n', obj.simulationId);
                fprintf('              ID: %d\n', obj.id);
                fprintf('              WORKERS: %d\n', obj.numWorkers);
                fprintf('              TOTAL CAPACITY: %d\n', obj.capacity);
                
                for t = 1:obj.numType
                    fprintf('              Type %-2d Max Capacity: %d\n', t, obj.maxCapacityPerType(t));
                end

                if obj.numSourceQueues > 0
                    sIds = cellfun(@(q) q.id, obj.sourceQueues);
                    fprintf('              SOURCE QUEUES: [%s]\n', num2str(sIds));
                else
                    fprintf('              SOURCE QUEUES: None\n');
                end
                
                if ~isempty(obj.destinationQueue)
                    fprintf('              DESTINATION QUEUE: %d\n', obj.destinationQueue.id);
                else
                    fprintf('              DESTINATION QUEUE: None\n');
                end
                fprintf('————————————————————————————————————————————————————————————\n');
            end
        end

        function [canServe, selectedCustomer, selectedWorker, selectedQueue]  = checkArrival(obj) 
            % determines if a worker is idle and a source queue has customers
            nonEmptyQueues = obj.sourceQueues(cellfun(@(q) q.lengthQueue > 0, obj.sourceQueues));

            if any(obj.availableWorkers) && ~isempty(nonEmptyQueues)
                id = find(obj.availableWorkers, 1); 
                queue = nonEmptyQueues{1}; % FIFO across queues

                canServe = true;
                selectedCustomer = queue.customersList(1);  % FIFO across customers 
                selectedWorker = obj.workersArray{id};
                selectedQueue = queue;
            else
                canServe = false;
                selectedCustomer = []; selectedWorker = []; selectedQueue = []; 
            end 
        end

        function handleArrival(obj, selectedCustomer, selectedWorker, selectedQueue, externalClock, eventsList, displayFlag)
            % processes entry: checks quotas, updates revenue, and starts service 
            selectedCustomer.path(end + 1) = obj.id; 
            selectedCustomer.startTime(obj.id) = externalClock;

            selectedWorker.startService(selectedCustomer, externalClock)
            obj.availableWorkers(selectedWorker.id) = 0;

            % capacity check: verify both total and type-specific limits
            type = selectedCustomer.type; 
            if obj.countPerType(type) < obj.maxCapacityPerType(type)
                if obj.occupiedSeat < obj.capacity
                    % record transaction and update revenue  
                    obj.countPerType(type) = obj.countPerType(type) + 1; 
                    obj.occupiedSeat = obj.occupiedSeat + 1;
                    obj.revenue = obj.revenue + obj.revenueDistribution(type);  
                end 
            end

            selectedQueue.handleExit(selectedCustomer, externalClock, displayFlag); 
            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to BUSY with Customer %d (Clock: %.2f)\n', ...
                obj.simulationId, selectedWorker.id, selectedCustomer.id, externalClock);
            end
            obj.updateClock(eventsList);
        end

        function handleWaiting(obj, externalClock, eventsList, displayFlag)
            % moves worker to WAITING when service ends
            obj.workerEvent.startWaiting(externalClock); 
            obj.waitingList{end+1} = obj.workerEvent;
           
            if  displayFlag        
                fprintf('[SERVER %d] Worker %d set to WAITING with Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, obj.workerEvent.id, obj.workerEvent.customer.id, externalClock);
            end
            obj.updateClock(eventsList); 
        end 


        function handleExit(obj, externalClock, eventsList, displayFlag)
            % completes exit: releases customer to destination queue and frees worker
            selectedWorker = obj.waitingList{1}; 
            obj.waitingList(1) = [];
            obj.availableWorkers(selectedWorker.id) = 1; 

            customer = selectedWorker.startExit(externalClock); 
            customer.endTime(obj.id) = externalClock; 

            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to IDLE released Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, selectedWorker.id, customer.id, externalClock);
            end

            obj.destinationQueue.handleArrival(customer, externalClock, displayFlag); 
            obj.count = obj.count + 1;
            obj.updateClock(eventsList);  
        end

        function exitFlag = checkExit(obj)        
            % returns true if a worker is waiting and the destination queue can accept them
            exitFlag = ~isempty(obj.waitingList) && obj.destinationQueue.checkArrival();
        end 

        function displayAgentState(obj, externalClock)
            % displayAgentState: Prints comprehensive performance metrics, including
            % revenue, quota breakdown, and detailed worker utilization.
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[SERVER %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d | TYPE: Priority Server\n', obj.id);
            fprintf('              TOTAL THROUGHPUT: %d customers\n', obj.count);
            fprintf('              TOTAL REVENUE:    %.2f\n', obj.revenue);
            
            occupancy = (obj.occupiedSeat / obj.capacity) * 100;
            fprintf('              GLOBAL OCCUPANCY: %d / %d (%.2f%%)\n', ...
                obj.occupiedSeat, obj.capacity, occupancy);
            
            fprintf('              ——————————————————————————————————————\n');
            fprintf('              BREAKDOWN BY CUSTOMER TYPE:\n');
            for t = 1:obj.numType
                typeCount = obj.countPerType(t);
                typeLimit = obj.maxCapacityPerType(t);
                quotaUsage = (typeCount / typeLimit) * 100;
                
                fprintf('              • Type %-2d: %3d served | Quota: %3d (%5.1f%%)\n', ...
                    t, typeCount, typeLimit, quotaUsage);
            end
            
            fprintf('              ——————————————————————————————————————\n');
            fprintf('              DETAILED WORKER UTILIZATION:\n');
            totalBusyTime = 0;
            for i = 1:obj.numWorkers
                obj.workersArray{i}.displayWorkerStats();
                totalBusyTime = totalBusyTime + obj.workersArray{i}.timeInBusy;
            end
            
            avgWorkerUtil = (totalBusyTime / (obj.numWorkers * externalClock)) * 100;
            fprintf('              ——————————————————————————————————————\n');
            fprintf('              OVERALL SERVER EFFICIENCY: %.2f%%\n', avgWorkerUtil);
            fprintf('————————————————————————————————————————————————————————————\n');
        end

        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = inf; 
            obj.count = 0;
            obj.revenue = 0; 
            obj.occupiedSeat = 0;
            obj.countPerType = zeros(1, obj.numType);
            obj.waitingList = worker.empty();
            for i = 1:obj.numWorkers, obj.workersArray{i}.clear(); end
        end 
    end
end

