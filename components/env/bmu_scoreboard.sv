class bmu_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(bmu_scoreboard)

  // Reference model instance
  bmu_reference_model ref_model;

  // Configurable latency for DUT (default 1)
  int unsigned latency = 1;

  // Pipeline to track input transactions for later comparison
  bmu_sequence_item cmd_pipe[$];

  // Analysis port to receive transactions from monitor
  uvm_analysis_imp#(bmu_sequence_item, bmu_scoreboard) exp;

  // Queue to store transactions ready for comparison
  bmu_sequence_item packetQueue[$];

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  // Build phase - create reference model and analysis port
  function void build_phase(uvm_phase phase); 
    super.build_phase(phase);
    exp = new("exp", this);
    ref_model = bmu_reference_model::type_id::create("ref_model");

    // Allow overriding latency via config_db
    if (uvm_config_db#(int unsigned)::get(this, "", "latency", latency))
      this.latency = latency;
  endfunction: build_phase

  // Write function - receive transactions from monitor
  function void write(bmu_sequence_item req); 
    bmu_sequence_item in_tr;
    bmu_sequence_item ready;

    // Flush pipeline on reset
    if (!req.rst_l) begin
      cmd_pipe.delete();
      `uvm_info("SCOREBOARD", "Reset observed -> clearing pipeline", UVM_MEDIUM)
      return;
    end

    // Store current input transaction into the pipeline
    in_tr = new();
    in_tr.a_in          = req.a_in;
    in_tr.b_in          = req.b_in;
    in_tr.ap            = req.ap;
    in_tr.valid_in      = req.valid_in;
    in_tr.csr_ren_in    = req.csr_ren_in;
    in_tr.csr_rddata_in = req.csr_rddata_in;
    in_tr.scan_mode     = req.scan_mode;
    in_tr.rst_l         = req.rst_l;
    cmd_pipe.push_back(in_tr);

    // If pipeline has enough history, pop transaction for comparison
    if (cmd_pipe.size() > latency) begin
      ready = cmd_pipe.pop_front();

      // Attach DUT outputs to the transaction
      ready.result_ff = req.result_ff;
      ready.error     = req.error;

      // Push ready transaction to comparison queue
      packetQueue.push_back(ready); 
    end
  endfunction: write

  // Utility function - return a comma-separated list of active signals
  function string get_active_signals(bmu_sequence_item packet);
    string active_signals[$];
    string signal_info;

    if (packet.ap.csr_write) active_signals.push_back("csr_write");
    if (packet.ap.csr_imm) active_signals.push_back("csr_imm");
    if (packet.ap.zbb) active_signals.push_back("zbb");
    if (packet.ap.zba) active_signals.push_back("zba");
    if (packet.ap.land) active_signals.push_back("land");
    if (packet.ap.lxor) active_signals.push_back("lxor");
    if (packet.ap.sll) active_signals.push_back("sll");
    if (packet.ap.sra) active_signals.push_back("sra");
    if (packet.ap.rol) active_signals.push_back("rol");
    if (packet.ap.bext) active_signals.push_back("bext");
    if (packet.ap.sh3add) active_signals.push_back("sh3add");
    if (packet.ap.add) active_signals.push_back("add");
    if (packet.ap.slt) active_signals.push_back("slt");
    if (packet.ap.unsign) active_signals.push_back("unsign");
    if (packet.ap.sub) active_signals.push_back("sub");
    if (packet.ap.clz) active_signals.push_back("clz");
    if (packet.ap.cpop) active_signals.push_back("cpop");
    if (packet.ap.siext_h) active_signals.push_back("siext_h");
    if (packet.ap.min) active_signals.push_back("min");
    if (packet.ap.packu) active_signals.push_back("packu");
    if (packet.ap.gorc) active_signals.push_back("gorc");

    if (active_signals.size() == 0)
      signal_info = "none";
    else begin
      signal_info = active_signals[0];
      foreach (active_signals[i]) if (i != 0) signal_info = {signal_info, ",", active_signals[i]};
    end

    return signal_info;
  endfunction: get_active_signals

  // Run phase - continuously validate transactions
  task run_phase(uvm_phase phase);
    bmu_sequence_item packet;
    struct packed {
      logic [31:0] data;
      logic error;
    } expected_result;
    bit match;
    string active_msg;

    forever begin
      wait(packetQueue.size > 0);
      packet = packetQueue.pop_front();

      // Compute expected result from reference model
      expected_result = ref_model.compute_result(packet);

      // Compare DUT outputs with expected outputs
      match = (packet.result_ff === expected_result.data) && 
              (packet.error === expected_result.error);

      // Get a string of active signals
      active_msg = get_active_signals(packet);

      // Log detailed info
      `uvm_info("Scoreboard", $sformatf(
        "Validating packet: a_in=%0h, b_in=%0h, valid_in=%0b, csr_ren_in=%0b, csr_rddata_in=%0h, scan_mode=%0b, rst_l=%0b | Active signals: %s | Outputs: result_ff=%0h, error=%0b", 
        packet.a_in, packet.b_in, packet.valid_in, packet.csr_ren_in, packet.csr_rddata_in,
        packet.scan_mode, packet.rst_l, active_msg, packet.result_ff, packet.error
      ), UVM_HIGH);

      // Log concise info
      `uvm_info("Scoreboard", $sformatf(
        "Inputs: a_in=%0h, b_in=%0h | Active signals: %s | Outputs: result_ff=%0h, error=%0b", 
        packet.a_in, packet.b_in, active_msg, packet.result_ff, packet.error
      ), UVM_MEDIUM);

      // Print match or mismatch result
      if (match) begin
        `uvm_info("PASS", "------ :: Match :: ------", UVM_LOW);  
        `uvm_info("MATCH", $sformatf(
          "Expected: result=%0h error=%0b | Got: result=%0h error=%0b", 
          expected_result.data, expected_result.error, packet.result_ff, packet.error
        ), UVM_LOW); 
      end else begin
        `uvm_error("FAIL", "------ :: Mismatch :: ------"); 
        `uvm_info("MISMATCH", $sformatf(
          "Expected: result=%0h error=%0b | Got: result=%0h error=%0b", 
          expected_result.data, expected_result.error, packet.result_ff, packet.error
        ), UVM_LOW); 
      end
    end
  endtask: run_phase

endclass: bmu_scoreboard
