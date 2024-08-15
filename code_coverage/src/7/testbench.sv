module testbench;

    logic [1:0] s;
    logic       a;
    logic       b;
    logic       c;

    decoder DUT (
        .s ( s ),
        .a ( a ),
        .b ( b ),
        .c ( c )
    );

    initial begin
        repeat(100_000_000) begin
            #10;
            s = $urandom();
        end
        $finish();
    end

endmodule