classdef customer < handle
    %CUSTOMER Summary of this class goes here
    %   Detailed explanation goes here
    properties
        id
        birthTime  % tempo di nascita processo
        startTime % tempo di entrata in un nodo del grafo 
        endTime % tempo di uscita 
        path % nodi percorsi 
        type 

    end
    
    methods
        function obj = customer(type, clock, networkLength)
            if nargin == 0
                obj.type = 0;
            else 
                % customer reale 
                obj.id = customerIdGenerator.getId();
                obj.birthTime = clock;
                obj.startTime = NaN(networkLength + 1,1); % consideriamo la coda finale di accumulo 
                obj.endTime = NaN(networkLength + 1,1); 
                obj.type = type;
                obj.path = []; % non si conosce lungheza a priori
            end
        end

        function dispCustomer(obj)
            disp(['ID: ', num2str(obj.id)]);
            disp(['Birth Time: ', num2str(obj.birthTime)]);
            disp(['Type: ', num2str(obj.type)]);
        end
    end
end

