classdef workerState
    % workerState: enumeration defining the operational lifecycle of a server worker.
    enumeration
        Idle  % worker is available and ready to accept a new customer.
        Busy  % worker is currently performing service.
        Waiting % service is finished, but the worker is blocked from releasing the customer.
    end
end

