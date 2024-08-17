module sum (
    input  logic       clk,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] c
);

    always_ff @( posedge clk) begin
        c <= a + b;
    end

endmodule