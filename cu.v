// Control unit - Signed, 9662e103-129a

module cu (
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    output reg program_running,
    output reg [1:0] current_state
);

    parameter FETCH = 2'b00;
    parameter DECODE = 2'b01;
    parameter EXECUTE = 2'b10;
	parameter MEMORY = 2'b11;
    parameter HALT_INSTRUCTION = 32'h00000000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            program_running <= 1;
            current_state <= FETCH;
        end else begin
            case (current_state)
                FETCH: begin
                    if (instruction == HALT_INSTRUCTION) begin
                        program_running <= 0;
                        current_state <= 2'bxx;
                    end
                    else begin
                        current_state <= DECODE;
                    end
                end
                
                DECODE: begin
                    current_state <= EXECUTE;
                end
                
                EXECUTE: begin
                    current_state <= MEMORY;
                end

                MEMORY: begin
                    current_state <= FETCH;
                end
                
                default: begin
                    program_running <= 0;
                end
            endcase
        end
    end
endmodule