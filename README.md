# DES - Discrete Event Simulation Framework

A modular, object-oriented framework in MATLAB for Discrete Event Simulation (DES) - a modeling approach where time is not advanced in fixed steps but jumps directly from one event to the next - events are generated dynamically during the simulation and the system state remains unchanged between them. The framework provides a shared simulation engine and a set of abstract base classes that can be extended to build custom scenarios with minimal effort - the user defines the behavior of each component, while the engine handles event scheduling, clock management, and state propagation.

Three application domains are included as built-in modules: **queueing networks**, **epidemic spreading**, and **game-theoretic dynamics**, each demonstrating how the same engine can be adapted to very different problem domains.

Developed as a homework for the **Business Analytics** course (Prof. Brandimarte, 2025) at **Politecnico di Torino**.

---

## Architecture

```
DES/
├── simulation/       Core engine: simulator and event list
├── queues/           Queueing networks: generators, queues, servers and examples
├── epidemics/        Epidemic models: SI, SIR, SIRS on contact networks
├── games/            Game-theoretic dynamics: players, policies and examples
├── setup.m           Adds all folders to the MATLAB path
└── run_tests.m       Runs the full test suite
```

The **simulator** maintains a global clock and a sorted event list. At each step it extracts the earliest event, advances the clock to that instant, executes the corresponding agent, and propagates any secondary effects before moving to the next event.

## Requirements

- **MATLAB** R2020b or later
- **Statistics and Machine Learning Toolbox** - used for `makedist` and `random`

---

## Getting Started

```bash
git clone https://github.com/ADemattia/DES.git
cd DES
```

```matlab
setup                                    % adds all folders to the MATLAB path
run('queues/examples/gasStation.m')      % run any example
```

---

## Modules

### Queueing Networks

Model service systems as directed networks of generators, queues, and servers. A `generator` creates `customer` entities with stochastic inter-arrival times and typed categories; `worker` units inside servers handle the actual service, tracking their own utilization. The behavior of queues and servers is fully customizable through the abstract base classes `queue` and `server` - the included implementations cover common patterns, but new variants can be created by subclassing and overriding a few methods.

**Included queue types:**
- `classicQueue` - FIFO buffer with finite or infinite capacity
- `balkingQueue` - hard capacity (guaranteed entry) plus soft capacity (probabilistic entry)

**Included server types:**
- `classicServer` - parallel independent workers, FIFO selection
- `priorityServer` - per-type capacity quotas and revenue tracking
- `lineFlowServer` - physical layout constraints where a rear customer blocks the exit of the one in front

**Examples:**
| Script | Scenario |
|---|---|
| `classicTest.m` | M/M/1 queue |
| `bufferTest.m` | Chain of servers with finite-capacity queues and blocking-after-service |
| `MM1Balking.m` | M/M/1 with balking queue: guaranteed, probabilistic, and rejection zones |
| `gasStation.m` | Gas pumps with physical constraints and payment kiosks |
| `revenueManagment.m` | Booking system with Littlewood's protection level |

### Epidemic Simulation

Simulate compartmental disease spreading (SI, SIR, SIRS) on contact networks. Each individual is an agent with stochastic meeting, recovery, and immunity-waning distributions.

| Script | Model | Description |
|---|---|---|
| `SImodel.m` | SI | No recovery - infection is permanent |
| `SIRmodel.m` | SIR | Permanent immunity after recovery |
| `SIRSmodel.m` | SIRS | Temporary immunity - agents can be reinfected |

### Game-Theoretic Dynamics

Simulate asynchronous dynamics on games played over networks. Each player is activated by an independent stochastic clock and updates its strategy according to a customizable decision policy and a user-defined utility function.

**Included policies:**
- `bestResponse` - deterministic utility maximization
- `learningDynamic` - Boltzmann/softmax with optional temperature decay
- `mistakeDynamic` - epsilon-greedy (best response with random exploration)

The `gameManager` tracks the full strategy trajectory and provides an interactive network visualization with a slider to step through the evolution.

| Script | Game |
|---|---|
| `majorityGame.m` | Coordination - players match the majority of neighbors |
| `publicGood.m` | Cooperation - players decide whether to contribute to a common pool |

---

## Writing Custom Simulations

Each module is built around abstract base classes that already handle event scheduling, statistics, and network wiring. To model a new scenario you only need to subclass and define the specific behavior — the signatures below show exactly which methods to implement and what each one is responsible for.

### Custom Queue

Subclass `queue` and implement four methods:

```matlab
classdef myQueue < queue
    methods
        function initialize(obj, eventsList, displayFlag) ... end
        % Called once before the simulation starts. Use it to set up initial state.

        function handleArrival(obj, customer, externalClock, displayFlag) ... end
        % Called when a customer arrives. Define the accept/reject logic here.

        function canEnter = checkArrival(obj) ... end
        % Returns true if the queue can accept a new customer. Controls blocking behavior.

        function clear(obj) ... end
        % Resets state and statistics for a new simulation run.
    end
end
```

Departure handling, time-weighted statistics, and network wiring are inherited from the base class.

### Custom Server

Subclass `server` and implement seven methods:

```matlab
classdef myServer < server
    methods
        function initialize(obj, eventsList, displayFlag) ... end
        % Set up initial state.

        function [canServe, customer, worker, queue] = checkArrival(obj) ... end
        % Decide which customer to serve next and with which worker.

        function handleArrival(obj, customer, worker, queue, externalClock, eventsList, displayFlag) ... end
        % Start service: assign the customer to the worker and schedule completion.

        function handleWaiting(obj, externalClock, eventsList, displayFlag) ... end
        % Service finished but the customer cannot leave yet (e.g., downstream queue is full).

        function handleExit(obj, externalClock, eventsList, displayFlag) ... end
        % Release the customer to the next queue and free the worker.

        function exitFlag = checkExit(obj) ... end
        % Returns true if a finished customer can move downstream.

        function clear(obj) ... end
        % Reset state and statistics.
    end
end
```

Worker management, clock synchronization, and the execute/update loop are inherited.

### Custom Decision Policy

Subclass `policy` and implement a single method:

```matlab
classdef myPolicy < policy
    methods
        function nextAction = updateAction(obj, managerId, profile, actionsSpace, utilityFunction)
            % Given the current strategy profile, return the next action for the player.
        end
    end
end
```

### Building a Queueing Network

1. Create node instances (generators, queues, servers) with their distributions.
2. Define the adjacency matrix - `1` at position `(i,j)` means node `i` feeds into node `j`.
3. Wire, run, and collect results:

```matlab
gen = generator(@() exprnd(1), 1, @() 1);
q   = classicQueue(false, false, inf);
s   = classicServer(1, @() exprnd(0.5));

network = networkQueue({gen, q, s}, [0 1 0; 0 0 1; 0 0 0]);
network.networkSetUp();

sim = simulator(100, {gen, q, s}, true);
sim.agentSetUp();
sim.executeSimulation();
sim.displayAgentStates();
network.statistic();
```

### Building a Game

1. Define the action space, utility functions, activation distributions, and a policy.
2. Create players and a `gameManager`.
3. Run:

```matlab
actionsSpace = [0, 1];
policy = bestResponse();

for i = 1:numPlayers
    utilityFn = @(profile) ...;  % payoff given the global strategy profile
    players{i} = player(actionsSpace, randi(2)-1, utilityFn, @() exprnd(0.5), policy);
end

gm = gameManager(players, actionsSpace);
sim = simulator(50, players, true);
sim.agentSetUp();
sim.executeSimulation();
gm.displayStats(adjacencyMatrix);
```

---

## License

Released under the MIT License. See `LICENSE.md` for details.
