// Interface - Signed, 9662e103-129a

/*
Instruction cycle
FETCH
Address in PC copied to MAR and sends a read command on the control bus
Instruction found at address described by MAR copied to the MDR
Instruction in MDR copied to the IR
PC incremented to "point" to next instruction

DECODE
CU decodes the contents of the IR

EXECUTE
CU sends signals to relevant components (i.e. ALU)

STORE
Outputs from instruction stored (if needed)
*/

module interface ();
    // mc
    reg rst;
    reg clk_en;
    wire clk;

    // flash
    reg cs;
	reg we;
	reg re;
	reg [23:0] addr;
	reg [7:0] in;
	wire [7:0] out;

    // pc
    reg [1:0] pc_handle;
    wire [23:0] pc_out;

	// registers
	reg [23:0] mar;
	reg [31:0] mbr;
	reg [31:0] ir;

	// cu
    wire [1:0] current_state;
    wire program_running;
    reg [23:0] current_addr;
    parameter FETCH = 2'b00;
    parameter DECODE = 2'b01;
    parameter EXECUTE = 2'b10;
	parameter MEMORY = 2'b11;
    parameter HALT_INSTRUCTION = 32'h00000000;

	// decode signals
    reg [6:0] opcode;
    reg [4:0] rd, rs1, rs2;
    reg [11:0] imm;
    reg [2:0] funct3;
    reg [6:0] funct7;
	reg [2:0] instruction_type;

	integer i;

    mc mc_inst (
        .rst(rst),
        .clk_en(clk_en),
        .clk(clk)
    );

    flash flash_inst (
        .clk(clk),
        .cs(cs),
		.we(we),
		.re(re),
		.addr(addr),
		.in(in),
		.out(out)
    );

    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_handle(pc_handle),
        .pc_out(pc_out)
    );

    cu cu_inst (
        .clk(clk),
        .rst(rst),
        .instruction(ir),
        .program_running(program_running),
        .current_state(current_state)
    );

    task startup;
        begin
            rst = 1;
            clk_en = 0;
            cs = 0;
            addr = 24'bx;
            in = 8'bx;
            we = 0;
			pc_handle = 2'b0;
			current_addr = 24'hx;

            #1
            rst = 0;
            clk_en = 1;
        end
    endtask

    task inc_pc;
        begin
            @(posedge clk);
            pc_handle = 2'b01;
            @(posedge clk);
            pc_handle = 2'b00;
        end
    endtask

	task write_byte;
        input [23:0] write_addr;
        input [7:0] write_data;

        begin
            cs = 1;
            @(posedge clk);
            we = 1;
            re = 0;
            addr = write_addr;
            in = write_data;
            @(posedge clk);
            we = 0;
			re = 1;
            cs = 0;
			addr = 24'hx;
			in = 8'bx;
        end
    endtask

    task write_instruction;
        input [23:0] start_addr;
        input [31:0] instruction;

        begin
            write_byte(start_addr, instruction[7:0]);
            write_byte(start_addr + 1, instruction[15:8]);   
            write_byte(start_addr + 2, instruction[23:16]);  
            write_byte(start_addr + 3, instruction[31:24]);
			current_addr = start_addr + 4;
        end
    endtask

    task fetch_instruction;
        reg [7:0] tbytes [3:0];
		integer i;

		output [31:0] ir;

        begin
            for (i = 0; i < 4; i = i + 1) begin
                @(posedge clk);
                mar = pc_out;
                cs = 1;
                @(posedge clk);
                addr = mar;
                we = 0;
                re = 1;
                repeat(3) @(posedge clk);
                tbytes[i] = out;
                addr = 24'hx;
                inc_pc();
            end
    
            @(posedge clk);
            mar = 24'hx;
            mbr = {tbytes[3], tbytes[2], tbytes[1], tbytes[0]};
            @(posedge clk);
            ir = mbr;
			repeat(2) @(posedge clk);
			$display("FETCH instruction=%h", ir);
			while (current_state == FETCH) @(posedge clk);
        end
    endtask

    task decode_instruction;
		input [31:0] ir;

        begin
			$display("FETCH instruction=%h", ir);
			
			opcode = ir[6:0];
			rd = ir[11:7];
			rs1 = ir[19:15];
			rs2 = ir[24:20];
			funct3 = ir[14:12];
			funct7 = ir[31:25];

			case (ir[6:0])
                7'b0110011: begin // R-type
                    instruction_type = 3'b000;
                    imm = 32'b0;
                end
                
                7'b0010011, 7'b0000011, 7'b1100111: begin  // I-type
                    instruction_type = 3'b001;
                    imm = {{20{ir[31]}}, ir[31:20]};
                end
                
                7'b0100011: begin // S-type
                    instruction_type = 3'b010;
                    imm = {{20{ir[31]}}, ir[31:25], ir[11:7]};
                end
                
                7'b1100011: begin // B-type
                    instruction_type = 3'b011;
                    imm = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
                end
                
                7'b0110111, 7'b0010111: begin // U-type
                    instruction_type = 3'b100;
                    imm = {ir[31:12], 12'b0};
                end
                
                7'b1101111: begin // J-type
                    instruction_type = 3'b101;
                    imm = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
                end
            endcase

			while (current_state == DECODE) @(posedge clk);
        end
    endtask

    task execute_instruction;
        begin

			while (current_state == EXECUTE) @(posedge clk);
        end
    endtask
	
    task memory_access;
        begin

			while (current_state == MEMORY) @(posedge clk);
        end
    endtask

    initial begin
        startup();
        
		// write sample instructions stage
        write_instruction(24'h000000, 32'h02000283);
		write_instruction(24'h000004, 32'h02100303);
		//write_instruction(24'h000008, 32'h006283b3);
		//write_instruction(24'h00000c, 32'h02700123);
		//write_byte(24'h000010, 8'b00000001);
		// end

		write_instruction(current_addr, HALT_INSTRUCTION);

        // fetch stage
        while (program_running) begin
            case (current_state)
                2'b00: fetch_instruction(ir);
                2'b01: decode_instruction(ir);
                2'b10: execute_instruction();
                2'b11: memory_access();
                default: ;
            endcase
        end

        @(posedge clk);

        $finish;
    end
endmodule