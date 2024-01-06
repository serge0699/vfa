module decoder (
    input  logic [1:0] s,
    output logic       a,
    output logic       b,
    output logic       c
);

    always_comb begin
        if( s[0] ) begin
            a = 0;
            b = 0;
            c = 0;
        end
        else begin
            case( s[1] )
                1'b0: begin
                    a = 0;
                    b = 1;
                    c = 1;
                end
                1'b1: begin
                    a = 1;
                    b = 1;
                    c = 1;
                end
            endcase
        end
    end

endmodule