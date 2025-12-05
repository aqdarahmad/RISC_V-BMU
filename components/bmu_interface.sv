interface bmu_interface(input logic clk);

  // =========================================================
  // INPUTS
  // =========================================================
  logic signed [31:0] a_in;       // Operand 1
  logic signed [31:0] b_in;       // Operand 2
  logic rst_l;                     // Active-low reset
  logic scan_mode;                 // Scan/test mode
  logic valid_in;                  // Input valid
  logic csr_ren_in;                // CSR read enable
  logic [31:0] csr_rddata_in;     // CSR read data

  // =========================================================
  // AP STRUCT: Arithmetic & Bitwise Operation Signals
  // =========================================================
  typedef struct packed {
    // CSR operations
    logic csr_write;
    logic csr_imm;

    // Extensions
    logic zbb;
    logic zba;

    // Logical
    logic land;
    logic lxor;

    // Shifts and rotates
    logic sll;
    logic sra;
    logic rol;
    logic bext;

    // Misc
    logic sh3add;

    // Arithmetic
    logic add;
    logic slt;
    logic unsign;
    logic sub;

    // Bit manipulation
    logic clz;
    logic cpop;
    logic siext_h;
    logic min;
    logic packu;
    logic gorc;

  } ap_struct_t;

  ap_struct_t ap;                 // Operation control signals

  // =========================================================
  // OUTPUTS
  // =========================================================
  logic [31:0] result_ff;         // Result output
  logic error;                    // Error flag

  // =========================================================
  // CLOCKING BLOCKS
  // =========================================================
  // Driver Clocking: signals driven by driver
  clocking driver_cb @(posedge clk);
    output rst_l, a_in, b_in, scan_mode, valid_in, csr_ren_in, csr_rddata_in;
    output ap;                    // Note: driver should drive individual fields if needed
    input  result_ff, error;      // Driver may sample DUT outputs
  endclocking

  // Monitor Clocking: signals observed by monitor
  clocking monitor_cb @(posedge clk);
    input rst_l, a_in, b_in, scan_mode, valid_in, csr_ren_in, csr_rddata_in;
    input ap;
    input result_ff, error;
  endclocking

  // =========================================================
  // MODPORTS
  // =========================================================
  modport driver_mod  (clocking driver_cb, input clk);
  modport monitor_mod (clocking monitor_cb, input clk);

endinterface : bmu_interface
