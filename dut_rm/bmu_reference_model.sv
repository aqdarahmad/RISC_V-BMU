class bmu_reference_model extends uvm_object;
    `uvm_object_utils(bmu_reference_model)
    
    // Store the current active signals
    string active_signals[$];
    
    // Store previous result to maintain RTL-like behavior
    logic [31:0] previous_result = 32'h0;
    logic previous_error = 1'b0;
    
    // Constructor
    function new(string name = "bmu_reference_model");
        super.new(name);
    endfunction
    
    // Function to record active signals from the packet
    virtual function void record_signals(input bmu_sequence_item packet);
        active_signals.delete();
        if (packet.ap.csr_write) active_signals.push_back("csr_write");
        if (packet.ap.csr_imm)   active_signals.push_back("csr_imm");
        if (packet.ap.zbb)       active_signals.push_back("zbb");
        if (packet.ap.zba)       active_signals.push_back("zba");
        if (packet.ap.land)      active_signals.push_back("land");
        if (packet.ap.lxor)      active_signals.push_back("lxor");
        if (packet.ap.sll)       active_signals.push_back("sll");
        if (packet.ap.sra)       active_signals.push_back("sra");
        if (packet.ap.rol)       active_signals.push_back("rol");
        if (packet.ap.bext)      active_signals.push_back("bext");
        if (packet.ap.sh3add)    active_signals.push_back("sh3add");
        if (packet.ap.add)       active_signals.push_back("add");
        if (packet.ap.slt)       active_signals.push_back("slt");
        if (packet.ap.unsign)    active_signals.push_back("unsign");
        if (packet.ap.sub)       active_signals.push_back("sub");
        if (packet.ap.clz)       active_signals.push_back("clz");
        if (packet.ap.cpop)      active_signals.push_back("cpop");
        if (packet.ap.siext_h)   active_signals.push_back("siext_h");
        if (packet.ap.min)       active_signals.push_back("min");
        if (packet.ap.packu)     active_signals.push_back("packu");
        if (packet.ap.gorc)      active_signals.push_back("gorc");
    endfunction
    
    // Validate signal combinations
    virtual function bit check_signals();
        int n = active_signals.size();
        
        if (n <= 1) return 1;           // 0 or 1 active signal is valid
        if (n > 3)  return 0;           // More than 3 signals invalid
        
        // Check valid 2-signal combinations
        if (n == 2) begin
            string s0 = active_signals[0];
            string s1 = active_signals[1];
            if ((s0=="csr_imm" && s1=="csr_write") || (s0=="csr_write" && s1=="csr_imm")) return 1;
            if ((s0=="land" && s1=="zbb") || (s0=="zbb" && s1=="land")) return 1;
            if ((s0=="lxor" && s1=="zbb") || (s0=="zbb" && s1=="lxor")) return 1;
            if ((s0=="sh3add" && s1=="zba") || (s0=="zba" && s1=="sh3add")) return 1;
            if ((s0=="slt" && s1=="sub") || (s0=="sub" && s1=="slt")) return 1;
            if ((s0=="min" && s1=="sub") || (s0=="sub" && s1=="min")) return 1;
            return 0;
        end
        
        // Check valid 3-signal combination
        if (n == 3) begin
            if ((active_signals[0]=="slt" && active_signals[1]=="unsign" && active_signals[2]=="sub") ||
                (active_signals[0]=="slt" && active_signals[1]=="sub" && active_signals[2]=="unsign") ||
                (active_signals[0]=="unsign" && active_signals[1]=="slt" && active_signals[2]=="sub") ||
                (active_signals[0]=="unsign" && active_signals[1]=="sub" && active_signals[2]=="slt") ||
                (active_signals[0]=="sub" && active_signals[1]=="slt" && active_signals[2]=="unsign") ||
                (active_signals[0]=="sub" && active_signals[1]=="unsign" && active_signals[2]=="slt"))
                return 1;
            else
                return 0;
        end
    endfunction
    
    // Compute BMU result
    virtual function struct packed {
        logic [31:0] data;
        logic error;
    } compute_result(input bmu_sequence_item packet);
        
        struct packed {
            logic [31:0] data;
            logic error;
        } result;
        
        result.data  = 32'h0;
        result.error = 1'b0;
        
        record_signals(packet);
        
        // Maintain previous value if not valid
        if (!packet.valid_in) begin
            result.data  = previous_result;
            result.error = previous_error;
            return result;
        end
        
        // Reset behavior
        if (!packet.rst_l) begin
            previous_result = 32'h0;
            previous_error  = 1'b0;
            return previous_result;
        end
        
        // CSR Read
        if (packet.csr_ren_in) begin
            if (active_signals.size()==0) result.data = packet.csr_rddata_in;
            else result.error = 1'b1; // conflict with active signals
            previous_result = result.data;
            previous_error  = result.error;
            return result;
        end
        
        // Validate signals
        if (!check_signals()) begin
            result.error = 1'b1;
            previous_result = result.data;
            previous_error  = result.error;
            return result;
        end
        
        // CSR Write / Immediate
        if (packet.ap.csr_write) begin
            result.data = packet.ap.csr_imm ? packet.b_in : packet.a_in;
            previous_result = result.data;
            previous_error  = result.error;
            return result;
        end
        
        // Logical Operations
        if (packet.ap.land && packet.ap.zbb)      result.data = packet.a_in & ~packet.b_in;
        else if (packet.ap.land)                 result.data = packet.a_in & packet.b_in;
        else if (packet.ap.lxor && packet.ap.zbb) result.data = packet.a_in ^ ~packet.b_in;
        else if (packet.ap.lxor)                 result.data = packet.a_in ^ packet.b_in;
        
        // Shifts and Rotates
        else if (packet.ap.sll)                  result.data = packet.a_in << packet.b_in[4:0];
        else if (packet.ap.sra)                  result.data = packet.a_in >>> packet.b_in[4:0];
        else if (packet.ap.rol)                  result.data = (packet.b_in[4:0]==0) ? packet.a_in : (packet.a_in << packet.b_in[4:0]) | (packet.a_in >> (32-packet.b_in[4:0]));
        else if (packet.ap.bext)                 result.data = {31'd0, packet.a_in[packet.b_in[4:0]]};
        else if (packet.ap.sh3add && packet.ap.zba) result.data = (packet.a_in << 3) + packet.b_in;
        
        // Arithmetic Operations
        else if (packet.ap.add)                  result.data = packet.a_in + packet.b_in;
        
        // Bit Manipulation
        else if (packet.ap.slt && packet.ap.sub)
            result.data = packet.ap.unsign ? ($unsigned(packet.a_in) < $unsigned(packet.b_in) ? 32'h1 : 32'h0)
                                           : ($signed(packet.a_in)   < $signed(packet.b_in)   ? 32'h1 : 32'h0);
        else if (packet.ap.clz) begin
            result.data = 32'h0;
            for (int i=31; i>=0; i--) if (!packet.a_in[i]) result.data++;
            else break;
        end
        else if (packet.ap.cpop) begin
            result.data = 32'h0;
            for (int i=0;i<32;i++) if (packet.a_in[i]) result.data++;
        end
        else if (packet.ap.siext_h) begin
            result.data = packet.a_in[15] ? {16'hFFFF, packet.a_in[15:0]} : {16'h0000, packet.a_in[15:0]};
        end
        else if (packet.ap.min && packet.ap.sub) result.data = ($signed(packet.a_in) < $signed(packet.b_in)) ? packet.a_in : packet.b_in;
        else if (packet.ap.packu) result.data = {packet.b_in[31:16], packet.a_in[31:16]};
        else if (packet.ap.gorc) begin
            result.data[31:24] = packet.a_in[31:24] ? 8'hFF : 8'h00;
            result.data[23:16] = packet.a_in[23:16] ? 8'hFF : 8'h00;
            result.data[15:8]  = packet.a_in[15:8]  ? 8'hFF : 8'h00;
            result.data[7:0]   = packet.a_in[7:0]   ? 8'hFF : 8'h00;
        end
        else result.error = 1'b1; // unsupported op
        
        // Update previous
        previous_result = result.data;
        previous_error  = result.error;
        return result;
        
    endfunction

endclass : bmu_reference_model
