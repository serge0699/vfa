module testbench;

    logic clk;
    logic resetn;
    logic req;
    logic we;
    logic ack;
    logic idle;
    logic read;
    logic write;

    fsm DUT (
        .clk    ( clk    ),
        .resetn ( resetn ),
        .req    ( req    ),
        .we     ( we     ),
        .ack    ( ack    ),
        .idle   ( idle   ),
        .read   ( read   ),
        .write  ( write  )
    );

    // Clock
    initial begin
        clk <= 0;
        forever begin
            #5 clk <= ~clk;
        end
    end

    // Reset
    initial begin
        resetn <= 0;
        @(posedge clk);
        resetn <= 1;
    end

    task set_inputs(logic [2:0] inputs);
        req <= inputs[2];
        we  <= inputs[1];
        ack <= inputs[0];
    endtask

    task check_outputs(logic [2:0] outputs);
        if( { idle, read, write } !== outputs )
            $error("Real: %3b, Expected: %3b",
                { idle, read, write }, outputs);
    endtask

    task wait_clocks(int num);
        repeat(num) @(posedge clk);
    endtask

    // Generate
    initial begin
        // Set initial values
        req <= 0;
        we  <= 0;
        ack <= 0;
        // Wait for unreset
        do wait_clocks(1); while(!resetn);
        // Check for idle state
        check_outputs(3'b100); // idle: 1, read: 0, write: 0
        // Check some transitions
        // 1
        set_inputs(3'b100); wait_clocks(2); // req: 1, we: 0, ack: 0
        check_outputs(3'b010); // idle: 0, read: 1, write: 0
        // 2
        set_inputs(3'b001); wait_clocks(2); // req: 0, we: 0, ack: 1
        check_outputs(3'b100); // idle: 1, read: 0, write: 0
        // 
        $finish();
    end


endmodule