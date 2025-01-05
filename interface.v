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

	// cu
	// INSTANTIATE LATER

	// registers
	reg [23:0] mar;
	reg [31:0] mbr;
	reg [31:0] ir;
	
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

    task startup;
        begin
            rst = 1;
            clk_en = 0;
            cs = 0;
            addr = 24'bx;
            in = 8'bx;
            we = 0;
			pc_handle = 2'b00;

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
        end
    endtask

	task fetch_instruction;
	    reg [7:0] tbytes [3:0];
	    integer i;

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
	    end
	endtask

    initial begin
        startup();

		// write sample instructions stage
        write_instruction(24'h000000, 32'h02000283);
		write_instruction(24'h000004, 32'h02100303);
		write_instruction(24'h000008, 32'h006283b3);
		write_instruction(24'h00000c, 32'h02700123);
		write_byte(24'h000010, 8'b00000001);
		// end

		// fetch stage
		fetch_instruction();


        @(posedge clk);

        $finish;
    end
endmodule