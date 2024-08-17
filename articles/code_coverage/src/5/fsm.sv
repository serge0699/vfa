module fsm (

    input  logic clk,
    input  logic resetn,

    input  logic req,
    input  logic we,
    input  logic ack,
    output logic idle,
    output logic read,
    output logic write

);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        READ  = 2'b01,
        WRITE = 2'b10
    } state_e;

    state_e nextstate, state_ff;

    assign idle  = state_ff == IDLE;
    assign read  = state_ff == READ;
    assign write = 0;

    always_ff @(posedge clk) begin
        if(!resetn) state_ff <= IDLE;
        else state_ff <= nextstate;
    end

    always_comb begin
        case(state_ff)
            IDLE: begin
                if( req ) nextstate = we ? WRITE : READ;
                else nextstate = IDLE;
            end
            READ: begin
                nextstate = ack ? IDLE : READ;
            end
            WRITE: begin
                nextstate = ack ? IDLE : WRITE;
            end
            default: nextstate = IDLE;
        endcase
    end

endmodule