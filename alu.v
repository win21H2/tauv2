// Arithmetic logic unit - Signed, 9662e103-129a

module alu (
    input wire clk,
    input wire rst,
    input wire [7:0] A, B,
    input wire alu_opcode,
    output reg [31:0] result,
    output reg cf, // carry
    output reg zf, // zero
    output reg nf, // negative 
    output reg of  // overflow
);

    reg [31:0] extended_A, extended_B;
    reg [32:0] temp;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
            cf <= 0;
            zf <= 0;
            nf <= 0;
            of <= 0;
        end else begin
            extended_A = {{24{A[7]}}, A};
            extended_B = {{24{B[7]}}, B};

            case (alu_opcode)
                1'h1: begin // ADD
                    temp = {1'b0, extended_A} + {1'b0, extended_B};
                    result <= temp[31:0];
                    cf <= temp[32];
                    of <= (extended_A[31] == extended_B[31]) && (result[31] != extended_A[31]);
                end
                1'h2: begin // SUB
                    temp = {1'b0, extended_A} - {1'b0, extended_B};
                    result <= temp[31:0];
                    cf <= temp[32];
                    of <= (extended_A[31] != extended_B[31]) && (result[31] != extended_A[31]);
                end
                1'h3: begin // AND
                    result <= extended_A & extended_B;
                    cf <= 0;
                    of <= 0;
                end
                1'h4: begin // OR
                    result <= extended_A | extended_B;
                    cf <= 0;
                    of <= 0;
                end
                1'h5: begin // XOR
                    result <= extended_A ^ extended_B;
                    cf <= 0;
                    of <= 0;
                end
                1'h6: begin // SLL
                    result <= extended_A << extended_B[4:0];
                    cf <= 0;
                    of <= 0;
                end
                1'h7: begin // SRL
                    result <= extended_A >> extended_B[4:0];
                    cf <= 0;
                    of <= 0;
                end
                1'h8: begin // SRA
                    result <= $signed(extended_A) >>> extended_B[4:0];
                    cf <= 0;
                    of <= 0;
                end
                1'h9: begin // SLT
                    result <= ($signed(extended_A) < $signed(extended_B)) ? 32'd1 : 32'd0;
                    cf <= 0;
                    of <= 0;
                end
                1'ha: begin // SLTU
                    result <= (extended_A < extended_B) ? 32'd1 : 32'd0;
                    cf <= 0;
                    of <= 0;
                end
                default: begin
                    result <= 32'b0;
                    cf <= 0;
                    of <= 0;
                end
            endcase

            zf <= (result == 32'b0);
            nf <= result[31];
        end
    end
endmodule