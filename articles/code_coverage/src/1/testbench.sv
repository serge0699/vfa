module testbench;

    logic [1:0] binary;
    logic [3:0] onehot;

    binary_to_onehot DUT (
        .binary ( binary ),
        .onehot ( onehot )
    );

    initial begin
        binary = 2'b11;
        #10;
        binary = 2'b01;
        #10;
        $finish();
    end

endmodule