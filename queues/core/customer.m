classdef customer < handle
    % customer: represents an entity moving through the simulation network
    % Stores identification, categorization, and timing data for 
    % each node visited to enable post-simulation performance analysis

    properties
        id % entity identifier 
        type % customer type 
        birthTime  % time when the customer entered the system
        startTime % vector: entry start time at each node
        endTime % vector: departure time from each node 
        path % ordered list of node IDs visited by the customer   
    end
    
    methods
        function obj = customer(type, clock, networkLength)
            % constructor: initializes timing vectors and ID
            if nargin == 0
                % null customer initialization
                obj.type = 0;
            else 
                obj.id = customerIdGenerator.getId();
                obj.birthTime = clock;
                obj.startTime = NaN(networkLength + 1,1); 
                obj.endTime = NaN(networkLength + 1,1); 
                obj.type = type;
                obj.path = []; 
            end
        end
        
        function dispCustomer(obj)
            % dispCustomer: prints a compact summary of customer data and network path
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('CUSTOMER ID: %-5d | TYPE: %d\n', obj.id, obj.type);
            fprintf('  Birth Time: %.2f\n', obj.birthTime);
            
            if ~isempty(obj.path)
                fprintf('  Path Taken: [%s]\n', num2str(obj.path));
                lastNode = obj.path(end);
                if ~isnan(obj.endTime(lastNode))
                    totalTime = obj.endTime(lastNode) - obj.birthTime;
                    fprintf('  Total Residence Time: %.2f\n', totalTime);
                end
            else
                fprintf('  Path Taken: Empty\n');
            end
            fprintf('————————————————————————————————————————————————————————————\n');
        end
    end
end

