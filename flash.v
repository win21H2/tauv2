// Flash - Signed, 9662e103-129a

module flash (
    input wire clk,
    input wire cs,
    input wire we,
    input wire re,
    input wire [23:0] addr,
    input wire [7:0] in,
    output reg [7:0] out
);
    reg [7:0] mem0 [0:1048575];
    reg [7:0] mem1 [0:1048575];
    reg [7:0] mem2 [0:1048575];
    reg [7:0] mem3 [0:1048575];
    reg [7:0] mem4 [0:1048575];
    reg [7:0] mem5 [0:1048575];
    reg [7:0] mem6 [0:1048575];
    reg [7:0] mem7 [0:1048575];
    reg [7:0] mem8 [0:1048575];
    reg [7:0] mem9 [0:1048575];
    reg [7:0] mem10 [0:1048575];
    reg [7:0] mem11 [0:1048575];
    reg [7:0] mem12 [0:1048575];
    reg [7:0] mem13 [0:1048575];
    reg [7:0] mem14 [0:1048575];
    reg [7:0] mem15 [0:1048575];

    wire write_protect;
    assign write_protect = (addr[23:20] == 4'b1111);

    always @(posedge clk) begin
        if (cs) begin
            if (we && !write_protect) begin     
                case (addr[23:20])
                    4'b0000: mem0[addr[19:0]] <= in;
                    4'b0001: mem1[addr[19:0]] <= in;
                    4'b0010: mem2[addr[19:0]] <= in;
                    4'b0011: mem3[addr[19:0]] <= in;
                    4'b0100: mem4[addr[19:0]] <= in;
                    4'b0101: mem5[addr[19:0]] <= in;
                    4'b0110: mem6[addr[19:0]] <= in;
                    4'b0111: mem7[addr[19:0]] <= in;
                    4'b1000: mem8[addr[19:0]] <= in;
                    4'b1001: mem9[addr[19:0]] <= in;
                    4'b1010: mem10[addr[19:0]] <= in;
                    4'b1011: mem11[addr[19:0]] <= in;
                    4'b1100: mem12[addr[19:0]] <= in;
                    4'b1101: mem13[addr[19:0]] <= in;
                    4'b1110: mem14[addr[19:0]] <= in;
                    4'b1111: mem15[addr[19:0]] <= in;
                endcase
            end

            if (re) begin
                case (addr[23:20])
                    4'b0000: out <= mem0[addr[19:0]];
                    4'b0001: out <= mem1[addr[19:0]];
                    4'b0010: out <= mem2[addr[19:0]];
                    4'b0011: out <= mem3[addr[19:0]];
                    4'b0100: out <= mem4[addr[19:0]];
                    4'b0101: out <= mem5[addr[19:0]];
                    4'b0110: out <= mem6[addr[19:0]];
                    4'b0111: out <= mem7[addr[19:0]];
                    4'b1000: out <= mem8[addr[19:0]];
                    4'b1001: out <= mem9[addr[19:0]];
                    4'b1010: out <= mem10[addr[19:0]];
                    4'b1011: out <= mem11[addr[19:0]];
                    4'b1100: out <= mem12[addr[19:0]];
                    4'b1101: out <= mem13[addr[19:0]];
                    4'b1110: out <= mem14[addr[19:0]];
                    4'b1111: out <= mem15[addr[19:0]];
                endcase
            end
        end
    end
endmodule