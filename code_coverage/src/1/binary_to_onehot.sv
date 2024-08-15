module binary_to_onehot (
    input  logic [1:0] binary,
    output logic [3:0] onehot
);

    always_comb begin
        case(binary)
            2'b00: onehot = 4'b0001;
            2'b01: onehot = 4'b0010;
            2'b10: onehot = 4'b0100;
            2'b11: onehot = 4'b1000;
        endcase
    end

endmodule