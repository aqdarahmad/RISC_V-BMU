class bmu_environment extends uvm_env;

  `uvm_component_utils(bmu_environment)

  bmu_agent agent;         // BMU agent instance
  bmu_scoreboard scoreboard; // Scoreboard instance to compare expected vs DUT outputs
  bmu_subscriber subscriber; // Analysis subscriber for observing transactions

  // Constructor
  function new(string name, uvm_component parent); 
    super.new(name, parent);
  endfunction: new

  // Build phase - create all components
  function void build_phase(uvm_phase phase); 
    super.build_phase(phase); 
    agent = bmu_agent::type_id::create("agent", this);
    scoreboard = bmu_scoreboard::type_id::create("scoreboard", this); 
    subscriber = bmu_subscriber::type_id::create("subscriber", this); 
  endfunction: build_phase

  // Connect phase - connect analysis ports
  function void connect_phase(uvm_phase phase);
    agent.monitor.port.connect(scoreboard.exp);              // Connect monitor to scoreboard
    agent.monitor.port.connect(subscriber.analysis_export); // Connect monitor to subscriber
  endfunction: connect_phase

endclass: bmu_environment
