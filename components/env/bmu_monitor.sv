class bmu_monitor extends uvm_monitor;

  `uvm_component_utils(bmu_monitor)

  virtual bmu_interface vif;                           // Virtual interface for driving/sampling DUT signals
  uvm_analysis_port#(bmu_sequence_item) port;          // Analysis port to send transactions to scoreboard/subscribers
  bmu_sequence_item packet;                             // Transaction object to store sampled signals

  // Constructor
  function new(string name = "bmu_monitor", uvm_component parent);
    super.new(name, parent);
    port = new("monitor_port", this);                 // Create analysis port
    packet = new();                                   // Create transaction object
  endfunction: new

  // Build phase - get the virtual interface
  function void build_phase(uvm_phase phase); 
    super.build_phase(phase);
    if(!uvm_config_db#(virtual bmu_interface)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface not set at top level");
  endfunction: build_phase

  // Run phase - continuously sample DUT signals and send transactions
  task run_phase(uvm_phase phase);
    forever begin
      // Wait for a clock edge or a callback to sample signals
      @(vif.monitor_cb);

      // Capture DUT signals into the transaction
      packet.a_in         = vif.monitor_cb.a_in;
      packet.b_in         = vif.monitor_cb.b_in;
      packet.rst_l        = vif.monitor_cb.rst_l;
      packet.scan_mode    = vif.monitor_cb.scan_mode;
      packet.valid_in     = vif.monitor_cb.valid_in;
      packet.csr_ren_in   = vif.monitor_cb.csr_ren_in;
      packet.csr_rddata_in= vif.monitor_cb.csr_rddata_in;
      packet.ap           = vif.monitor_cb.ap;
      packet.result_ff    = vif.monitor_cb.result_ff;
      packet.error        = vif.monitor_cb.error;

      // Log the sampled transaction
      `uvm_info("Monitor", $sformatf(
        "Signals from DUT: A=%0d | B=%0d | scan_mode=%b | valid_in=%b | csr_ren_in=%b | csr_rddata_in=%0d | ap=%p | result_ff=%0d | error=%b",
        packet.a_in, packet.b_in, packet.scan_mode, packet.valid_in, packet.csr_ren_in,
        packet.csr_rddata_in, packet.ap, packet.result_ff, packet.error
      ), UVM_HIGH);

      // Send the sampled transaction to connected analysis ports (scoreboard, subscribers)
      port.write(packet);
    end
  endtask: run_phase

endclass: bmu_monitor
