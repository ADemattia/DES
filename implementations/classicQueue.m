classdef classicQueue < queue
    % coda classica con politica accept/reject su base capacità 
    
    properties
        capacity % numero massimo customer 
    end
    
    methods
        function obj = classicQueue(overtakingFlag, waitingFlag, capacity)
            % chiamata a costruttore classe astratta 
            obj@queue(overtakingFlag,waitingFlag); 

            % proprietà caratteristiche 
            obj.capacity = capacity; 
        end

        % gestione nuovo customer 
        function arrivalManagment(obj, customer)

            % aggiornamento path ed eventi customer 
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = obj.clock;

            % politica di accettazione 
            if obj.lengthQueue < obj.capacity 
                % inserimento in coda 
                obj.customerList(end + 1) = customer;

                % aggiornamento conteggio
                obj.lengthQueue = obj.lengthQueue + 1; 
                obj.count = obj.count + 1;   

            else % obj.lengthQueue == obj.capacity - tutto occupato 
                obj.lostCustomer = obj.lostCustomer + 1; 
            end 
        end

        % la coda può accogliere nuovo customer da server? 
        function isAvailable = isQueueAvailable(obj)
            if obj.waitingFlag == false % il customer non aspetta, entra subito 
                isAvailable = true; 
            elseif obj.waitingFlag == true % il customer può aspettare nel server 
                if obj.lengthQueue < obj.capacity
                    isAvailable = true; 
                else % obj.lengthQueue >= obj.capacity - customer aspetta nel server che la coda si liberi
                    isAvailable = false; 
                end
            end
        end 


        function printStats(obj)
            fprintf('Lunghezza coda: %d\n', obj.lengthQueue);
            fprintf('Clienti persi: %d\n', obj.lostCustomer);
            fprintf('------------------------\n');
        end

        % Pulitore statistiche 
        function clearQueue(obj)
        obj.clock = 0;
        obj.customerList = customer.empty();
        obj.lengthQueue = 0;
        obj.count = 0;
        obj.lostCustomer = 0;
        obj.averageLength = 0; 
        end
    end
end

