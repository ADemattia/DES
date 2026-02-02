classdef individualState
    % individualState: enumeration defining the health status of an entity
    enumeration
        Susceptible   % susceptible individual - healthy but can be infected
        Infected    % infected individual - capable of spreading the pathogen 
        Recovered     % recovered individual - no longer infectious and has gained immunity
    end
end
