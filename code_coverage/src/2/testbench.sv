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
        s = 2'b00;
        #10;
        s = 2'b10;
        #10;
        $finish();
    end

endmodule