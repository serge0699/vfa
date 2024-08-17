module testbench();

    logic       clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;

    sum DUT (
        .clk(clk),
        .a  (a  ),
        .b  (b  ),
        .c  (c  )
    );

    initial begin
        clk <= 0;
        forever #10 clk <= ~clk;
    end

    initial begin
        repeat(10) begin
            @(posedge clk);
            a <= $urandom_range(0, 5);
            b <= $urandom_range(0, 5);
        end
        $stop();
    end

    typedef struct {
        logic [7:0] a;
        logic [7:0] b;
        logic [7:0] c;
    } packet;

    mailbox#(packet) mbx = new();
    packet p;

    initial begin
        forever begin
            @(posedge clk);
            p.a = a;
            p.b = b;
            p.c = c;
            mbx.put(p);
        end
    end

    packet p1, p2;

    initial begin
        mbx.get(p1);
        forever begin
            mbx.get(p2);
            if( p2.c !== p1.a + p1.b ) begin
                $error("%t Real: %h, Expected: %h",
                    $time(), p2.c, p1.a + p1.b);
            end
            p1 = p2;
        end
    end

endmodule