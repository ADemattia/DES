classdef classicQueue < queue
    % classicQueue: a standard queue with a finite capacity buffer
    % Implements accept/reject logic based on a fixed maximum capacity
    
    properties
        capacity % maximum number of customers allowed in the buffer  
    end
    
    methods
        function obj = classicQueue(overtakingFlag, waitingFlag, capacity)
            % constructor: initializes buffer limits
            obj@queue(overtakingFlag, waitingFlag); 
            obj.capacity = capacity; 
        end

        function initialize(obj, ~, displayFlag)

            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[QUEUE  %-3d] TYPE: Classic Queue (Finite Buffer)\n', obj.simulationId);
                fprintf('              ID: %d\n', obj.id);
                fprintf('              CAPACITY: %d\n', obj.capacity);
                
                overtakeStr = 'OFF'; if obj.overtakingFlag; overtakeStr = 'ON'; end
                waitingStr  = 'REJECT (Lost)'; if obj.waitingFlag; waitingStr = 'BLOCKING (Server waits)'; end
                
                fprintf('              OVERTAKING: %s\n', overtakeStr);
                fprintf('              WAITING POLICY: %s\n', waitingStr);

                sServers = [];
                for i = 1:length(obj.sourceServers)
                    sServers(end+1) = obj.sourceServers{i}.id;
                end
                
                sGens = [];
                for i = 1:length(obj.sourceGenerators)
                    sGens(end+1) = obj.sourceGenerators{i}.id;
                end
                
                fprintf('              SOURCE SERVERS: [%s]\n', num2str(sServers));
                fprintf('              SOURCE GENERATORS: [%s]\n', num2str(sGens));
                
                if ~isempty(obj.destinationServer)
                    fprintf('              DESTINATION SERVER: %d\n', obj.destinationServer.id);
                else
                    fprintf('              DESTINATION SERVER: None (Sink Queue)\n');
                end
                fprintf('————————————————————————————————————————————————————————————\n');
            end
        end

        function handleArrival(obj, customer, externalClock, displayFlag)
            % handleArrival: processes entry if space is available, otherwise registers loss
            if displayFlag
                fprintf('[QUEUE %d] Customer %d ARRIVAL (Clock: %.2f)\n', ...
                    obj.simulationId, customer.id, externalClock);
            end

            customer.path(end + 1) = obj.id; 
            customer.startTime(obj.id) = externalClock;
            obj.updateStat(externalClock);

            if obj.lengthQueue < obj.capacity
                % buffer available: accept customer
                obj.customersList(end + 1) = customer;
                obj.lengthQueue = obj.lengthQueue + 1; 
                obj.count = obj.count + 1;   
            else
                % buffer full: register lost customer
                obj.lostCustomers = obj.lostCustomers + 1; 
            end 
        end

        function canArrive = checkArrival(obj)
            % checkArrival: returns true if the source server can push the customer
            % if waitingFlag is false, the queue always accepts (customers are lost if full)
            % if waitingFlag is true, the queue only accepts if there is available capacity
            canArrive = ~obj.waitingFlag || (obj.lengthQueue < obj.capacity);
        end

        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = inf; 
            obj.customerList = customer.empty();
            obj.lengthQueue = 0; 
            obj.count = 0; 
            obj.lostCustomer = 0;
            obj.averageLength = 0; 
        end
    end
end

