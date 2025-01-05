// Program counter - Signed, 9662e103-129a

/*
To add in later revisions:
 - jump
 - branch
*/

module pc (
	input wire clk,
	input wire rst,
	input wire [1:0] pc_handle,
	output reg [23:0] pc_out
);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			pc_out <= 24'b0;
		end
		else begin
			case(pc_handle)
				2'b00: pc_out <= pc_out; // hold
				2'b01: pc_out <= pc_out + 1; // increment
			endcase
		end
	end
endmodule