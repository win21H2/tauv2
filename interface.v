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

    // alu
    reg [7:0] A, B;
    reg alu_opcode;
    wire [31:0] result;
    wire cf;
    wire zf;
    wire nf;
    wire of;

    // decode signals
    reg [6:0] opcode;
    reg [4:0] rd, rs1, rs2;
    reg [11:0] imm;
    reg [2:0] funct3;
    reg [6:0] funct7;

    reg [31:0] register [31:0];  // MOVE REGISTERS AND EFFECTIVE_ADDRESS TO A REGISTER FILE FILE
	reg [23:0] eff_addr;

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

    alu alu_inst (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .alu_opcode(alu_opcode),
        .result(result),
        .cf(cf),
        .zf(zf),
        .nf(nf),
        .of(of)
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
			re = 0;
            cs = 0;
			addr = 24'hx;
			in = 8'bx;
        end
    endtask

    task write_instruction; // figure out how to store without having delays between each store (i.e. store a full instruction all at once)
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

        begin
			$display("TASK: FETCH");

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
			we = 0;
			re = 0;
			cs = 0;
			while (current_state == FETCH) @(posedge clk);
        end
    endtask

	task decode_instruction;

		begin
		    $display("TASK: DECODE");

		    opcode = ir[6:0];
		    funct3 = ir[14:12];
			rs1 = ir[19:15];
		
		    case (opcode)
		        7'b0110011: begin
		            funct7 = ir[31:25];
		            imm = 32'bx;
					rs2 = ir[24:20];
					rd = ir[11:7];
					$display("R-TYPE: opcode [%h], rd [%h], rs1 [%h], rs2 [%h], funct3 [%h], funct7 [%h]", opcode, rd, rs1, rs2, funct3, funct7);
		        end
		        7'b0010011: begin
		            funct7 = 7'bx;
		            imm = {{20{ir[31]}}, ir[31:20]};
					rs2 = 5'bx;
					rd = ir[11:7];
					$display("I-TYPE: opcode [%h], rd [%h], rs1 [%h], funct3 [%h], imm [%h]", opcode, rd, rs1, funct3, imm);
		        end
				7'b0000011: begin
				    funct7 = 7'bx;
				    imm = {{20{ir[31]}}, ir[31:20]};
				    rs2 = 5'bx;
				    rd = ir[11:7];
					@(posedge clk);
					$display("I-TYPE: opcode [%h], rd [%h], rs1 [%h], funct3 [%h], imm [%h]", opcode, rd, rs1, funct3, imm);
				end
		        7'b0100011: begin
				    funct7 = 7'bx;
				    imm = {{20{ir[31]}}, ir[31:25], ir[11:7]};
				    rs2 = ir[24:20];
				    rd = 5'bx;
					$display("S-TYPE: opcode [%h], rs1 [%h], rs2 [%h], funct3 [%h], imm [%h]", opcode, rs1, rs2, funct3, imm);
				end
				7'b1100011: begin
				    funct7 = 7'bx;
				    imm = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
				    rs2 = ir[24:20];
				    rd = 5'bx;
					$display("B-TYPE: opcode [%h], rs1 [%h], rs2 [%h], funct3 [%h], imm [%h]", opcode, rs1, rs2, funct3, imm);
				end
				default: ;
		    endcase
		
		    we = 0;
		    re = 0;
		    cs = 0;
		    while (current_state == DECODE) @(posedge clk);
		end
	endtask

	task execute_instruction;

	    begin
			$display("TASK: EXECUTE");

			/*
				h1 - ADD
				h2 - SUB
				h3 - AND
				h4 - OR
				h5 - XOR
				h6 - SLL
				h7 - SRL
				h8 - SRA
				h9 - SLT
				ha - SLTU
			*/

			A = register[rs1];
			B = register[rs2];

			case (opcode)
				7'b0000011, 7'b0100011: ;
				7'b0110011: begin
					case (funct3)
			        	3'h0: alu_opcode = (funct7 == 7'h0) ? 1'h1 : 1'h2;
			        	3'h4: alu_opcode = 1'h5;
			        	3'h6: alu_opcode = 1'h4;
			        	3'h7: alu_opcode = 1'h3;
			        	3'h1: alu_opcode = 1'h6;
			        	3'h5: alu_opcode = (funct7 == 7'h0) ? 1'h7 : 1'h8;
			        	3'h2: alu_opcode = 1'h9;
			        	3'h3: alu_opcode = 1'ha;
			        	default: alu_opcode = 1'h0;
			    	endcase
				end
				7'b0010011: begin
					// TODO: ADD DECODES HERE
				end
				7'b1100011: begin
					// TODO: ADD DECODES HERE
				end
				default: ;
			endcase
			
			repeat(2) @(posedge clk);
			register[rd] = result;
			repeat(2) @(posedge clk);
			
			we = 0;
			re = 0;
			cs = 0;
	        while (current_state == EXECUTE) @(posedge clk);
	    end
	endtask

    reg first_memory_access = 1;

    task memory_access;

        begin
			if (!first_memory_access) begin
				$display("TASK: MEMORY");	
				eff_addr = imm + rs1;	

				case (opcode)
					7'b0000011: begin
						we = 0;
						re = 1;
						cs = 1;
						repeat(2) @(posedge clk);
						addr = eff_addr;
						repeat(2) @(posedge clk);
						register[rd] = out;
						re = 0;
						cs = 0;
					end
					7'b0100011: begin
						we = 1;
						re = 0;
						cs = 1;
						repeat(2) @(posedge clk);
						addr = eff_addr;
						repeat(2) @(posedge clk);
						in = register[rs2][7:0];
						we = 0;
						cs = 0;
					end
					default: ;
				endcase					
            end else begin
                first_memory_access = 0;
            end

			we = 0;
			re = 0;
			cs = 0;
            while (current_state == MEMORY) @(posedge clk);
        end
    endtask

    initial begin
        startup();
        
        write_instruction(24'h000000, 32'h02000283);
		write_instruction(24'h000004, 32'h02100303);
		write_instruction(24'h000008, 32'h006283b3);
		write_instruction(24'h00000c, 32'h02700123);
		write_byte(24'h000020, 8'h10); // 0x10 is 16 in decimal
		write_byte(24'h000021, 8'h04); // 0x04 is 4 in decimal
		// therefore the addition should be 20 in decimal which is 0x14 in hex
		write_instruction(current_addr, HALT_INSTRUCTION);

        while (program_running) begin
            case (current_state)
                2'b00: fetch_instruction();
				2'b01: decode_instruction();
                2'b10: execute_instruction();
                2'b11: memory_access();
                default: ;
            endcase
        end

        @(posedge clk);
        $finish;
    end
endmodule