// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// SystemVerilog Assertions и event regions.

module signextend(
    input  logic        clk_i,
    input  logic        aresetn_i,
    input  logic [ 7:0] data_i,
    output logic [31:0] data_o
);

    always_ff @(posedge clk_i or negedge aresetn_i) begin
        if(!aresetn_i) begin
            data_o <= 'b0;
        end
        else begin
            // NOTE: вычисление знакорасширения
            // сломано в данном примере.
            data_o <= {{23{data_i[7]}}, data_i};
        end
    end

endmodule

// В модуле ниже не модуль ~signextend~ подаются
// входные воздействия и при помощи SystemVerilog
// assertion и property ~pData~ проверяется кор-
// ректность его работы. Модуль "сломан" и генери-
// рует неверные выходные данные.

// SVA генерирует описанную пользователем ошиб-
// ку. Для верного отображения выходных данных,
// которые проверялись, необходимо использовать
// системную функцию $sampled(), которая возвра-
// щает значение переданного в нее аргумента на
// момент захватывания данных в SVA для провер-
// ки.

// Данные для проверки в SVA захватываются в
// preponed region (см. SystemVerilog IEEE Std
// 1800-2023 раздел 16.5.1). Вызов же $error()
// производится в reactive region (SystemVerilog
// IEEE Std 1800-2023 раздел 16.4.1). Между эти-
// ми регионами (preponed и reactive) выполняет-
// ся регион NBA, в котором может произойти из-
// менение на выходе триггера, что приведет к
// изменению значения ~data_o~. То есть SVA про-
// веряет значение как бы из предыдущего такта,
// а при вызове $error() выводится значение те-
// кущего такта.

// Для визуализации примера в QuestaSim выполните:
// run_questa.sh sva_sampled -gui

module sva_event_regions;

    logic        clk_i;
    logic        aresetn_i;
    logic [ 7:0] data_i;
    logic [31:0] data_o;

    signextend DUT (
        .clk_i     (clk_i     ),
        .aresetn_i (aresetn_i ),
        .data_i    (data_i    ),
        .data_o    (data_o    )
    );

    initial begin
        clk_i <= 0;
        forever #5 clk_i = ~clk_i;
    end

    initial begin
        aresetn_i <= 0;
        repeat(5) @(posedge clk_i);
        aresetn_i <= 1;
    end

    initial begin
        wait(aresetn_i === 1'b0);
        data_i <= 8'b0;
        wait(aresetn_i === 1'b1);
        repeat(5) begin
            @(posedge clk_i);
            data_i <= $urandom();
        end
        @(posedge clk_i);
        $finish();
    end

    property pData;
        logic [7:0] data;
        @(posedge clk_i) disable iff(!aresetn_i)
        (1, data = data_i) ##1 data_o === {{24{data[7]}}, data};
    endproperty

    apData: assert property(pData) else begin
        $error("data_i was: %h, data_o is: %h",
            $past(data_i, 1), $sampled(data_o));
    end

endmodule
