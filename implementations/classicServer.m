classdef classicServer < server
    % server classico con s servitori (finiti) che lavorano in parallelo
    % si possono caratterizzare per tempo di servizio con
    % serverDistribution(serverId) 
    
    methods
        function  obj = classicServer(numServer, serverDistribution, revenueFunction)
            obj@server(numServer, serverDistribution, revenueFunction); 
        end
        
        % è possibile servire un nuovo customer? 
        function [servicePossible, selectedCustomer] = checkAvailability(obj) 

            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % è disponibile almeno un serivitore? 
            if obj.notFullyOccupied == true
                % selezione customer 
                for i = 1 : obj.numPreviousQueues  % nessuna prioritarità
                    currentQueue = obj.previousQueues(i);
                    if currentQueue.lengthQueue > 0
                        servicePossible = 1; 
                        % selezionato customer e coda di provenienza 
                        selectedCustomer = currentQueue.customerList(1);
                        obj.selectedQueue = currentQueue;  
                        return;
                    end
                end
            end
        end

        % schedulazione nuovo evento 
        function scheduleNextEvents(obj, customer, externalClock)

            % aggiornamento path ed eventi customer 
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock; 

            % gestione uscita customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer); 

            % gestione assegnazione server 
            serverId = find(obj.serverState == serverState.Free, 1); % trova primo server libero 
            obj.updateServerTime(serverId, externalClock); % aggiorna statistiche server  
            obj.serverState(serverId) = serverState.Working; % occupa il server
            obj.customerToServer(serverId) = customer; % assegna customer a server

            % tempo servizio 
            serviceTime = obj.serverDistribution(serverId);  
            obj.clockServer(serverId) = externalClock + serviceTime; 

            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione
        end

        % sposta un customer in coda waiting e aggiorna server in modalità waiting 
        function addWaiting(obj, externalClock) 

            % ricerca customer e spostamento in waiting list 
            customer = obj.customerToServer(obj.eventServer); 
            obj.exitWaitingList(end+1) = customer; 

            % gestione stato server
            obj.clockServer(obj.eventServer) = inf;    % tempo server riportato a inf
            obj.updateServerTime(obj.eventServer, externalClock); % aggiorna statistiche server
            obj.serverState(obj.eventServer) = serverState.Waiting; % server in wait

            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione  
        end 

        % fa uscire customer e aggiorna server in modalità free 
        function exitCustomer(obj, externalClock)
            % aggiornamento statistiche 
            obj.count = obj.count + 1; 

            % scelto primo customer da fare uscire (nessuna priorità) 
            exitCustomer = obj.exitWaitingList(1); 
            obj.exitWaitingList(1) = []; % eliminazione da lista waiting 

            % aggiornamento eventi del customer 
            exitCustomer.endTime(obj.id) = externalClock;    

            % server che sta servendo il customer 
            [~, serverId] = obj.getServerFromCustomer(exitCustomer); 

            % gestione arrivo in coda di destinazione 
            arrivalQueue = obj.destinationQueue;  
            arrivalQueue.arrivalManagment(exitCustomer);  

            % gestione liberazione server 
            obj.customerToServer(serverId) = customer();  % impostato customer di default
            obj.updateServerTime(serverId, externalClock);
            obj.serverState(serverId) = serverState.Free;  % server ritorna libero

            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione 
        end

        % Pulitore statistiche 
        function clearServer(obj)
            obj.clock = inf; 
            obj.count = 0; 
            obj.notFullyOccupied = 1; 
            obj.customerToServer = repmat(customer(), obj.numServer, 1); 
            obj.serverState = repmat(serverState.Free, obj.numServer, 1);
            obj.exitWaitingList = customer.empty();
            obj.clockServer = inf(obj.numServer,1);
            obj.revenue = 0;
            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(obj.numServer,1); % inizializzata a zero  
        end 

    end
end

