// SystemVerilog Gotchas, Tips and Tricks, часть 2.

// Конфигурация массива агентов.

package icon_dv_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Элемент последовательности для работы с интерконнектом.

    class icon_seq_item extends uvm_sequence_item;

        `uvm_object_utils(icon_seq_item)

        rand byte addr;
        rand int  data;

        function new(string name = "");
            super.new(name);
        endfunction

        virtual function string convert2string();
            string str = $sformatf(
                "addr: %h, data: %h", addr, data);
            return str;
        endfunction

    endclass

    // Последовательность для работы с интерконнектом.

    class icon_seq extends uvm_sequence#(icon_seq_item);

        `uvm_object_utils(icon_seq)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            repeat(10) begin
                req = REQ::type_id::create("req");
                start_item(req);
                void'(req.randomize());
                finish_item(req);
            end
        endtask

    endclass

    // Секвенсер для работы с интерконнектом.

    typedef uvm_sequencer#(icon_seq_item) icon_sequencer;

    // Драйвер для работы с интерконнектом.
    // Получает интерфейс из базы ресурсов.
    // Реализует простейшую передачу данных.
    // См. метод ~drive()~.

    class icon_driver extends uvm_driver#(icon_seq_item);

        `uvm_component_utils(icon_driver)

        // Интерфейс интерконнекта.
        virtual icon_intf vif;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            if(!uvm_resource_db#(virtual icon_intf)::read_by_name(
                get_full_name(), "vif", vif))
                begin
                    `uvm_fatal(get_full_name(), "Can't get 'vif'!");
                end
        endfunction

        virtual task main_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);
                `uvm_info(get_name(), "Got item!", UVM_MEDIUM);
                drive();
                `uvm_info(get_name(), "Drived Item!", UVM_MEDIUM);
                seq_item_port.item_done();
            end
        endtask

        virtual task drive();
            repeat($urandom_range(0, 10)) begin
                @(posedge vif.clk);
            end
            vif.valid <= 1'b1;
            vif.addr  <= req.addr;
            vif.data  <= req.data;
            @(posedge vif.clk);
            vif.valid <= 1'b0;
        endtask

    endclass

    // Агент для работы с интерконнектом. Инкапсулирует
    // секвенсер и драйвер. Монитор в данном примере
    // не используется.

    class icon_agent extends uvm_agent;

        `uvm_component_utils(icon_agent)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        icon_sequencer sqr;
        icon_driver    drv;

        virtual function void build_phase(uvm_phase phase);
            sqr = icon_sequencer::type_id::create("sqr", this);
            drv = icon_driver::type_id::create("drv", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction

    endclass

    // Класс теста интерконнекта. Инкапсулирует
    // в себе динамические массивы agent и sequence.

    // В build_phase() в зависимости от получен-
    // ного из базы ресурсов количества агентов
    // создается их массив, а также массив вир-
    // туальных интерфейсов.

    // Получение виртуальных интерфейсов из базы
    // ресурсов производится по полному иерархичес-
    // кому имени и имени интерфейса с индексом.
    // Отправка в базу ресурсов для конкретных драй-
    // веров будет осуществляться по конкатенации
    // полного иерархического имени теста, иерархи-
    // ческого пути до агента с индексом и имени
    // интерфейса "vif".

    class icon_test extends uvm_test;

        `uvm_component_utils(icon_test)

        // Количество агентов.
        int ag_num;

        // Массив агентов и последовательностей.
        icon_agent ag  [];
        icon_seq   seq [];

        // Массив интерфейсов.
        virtual icon_intf vif [];

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            void'(uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_num", ag_num));
            ag  = new[ag_num];
            vif = new[ag_num];
            foreach(ag[i]) begin
                ag[i] = icon_agent::type_id::create(
                    $sformatf("ag_%0d", i), this);
            end
            foreach(ag[i]) begin
                void'(uvm_resource_db#(virtual icon_intf)::read_by_name(
                    get_full_name(), $sformatf("vif_%0d", i), vif[i]));
            end
            foreach(vif[i]) begin
                uvm_resource_db#(virtual icon_intf)::set(
                    {get_full_name(), $sformatf(".ag_%0d.drv", i)}, "vif", vif[i]);
            end
        endfunction

        virtual task main_phase(uvm_phase phase);
            phase.raise_objection(this);
            seq = new[ag_num];
            foreach(seq[i]) begin
                seq[i] = icon_seq::type_id::create(
                    $sformatf("seq_%0d", i));
            end
            foreach(seq[i]) begin
                fork
                    int j = i;
                    seq[j].start(ag[j].sqr);
                join_none
            end
            wait fork;
            phase.drop_objection(this);
        endtask

    endclass

endpackage

// Простейший интерфейс для взаимодействия
// с интерконнектом. Адрес, данные и сигнал
// об их валидности.

interface icon_intf(input logic clk);
    logic        valid;
    logic [ 7:0] addr;
    logic [31:0] data;
endinterface

// Модуль для запуска теста ~icon_test~.
// Количество агентов в примере может
// быть переопределено из командной строки.

module agent_array;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import icon_dv_pkg::*;

    // Количество агентов.
    parameter AG_NUM = 8;

    // Генерация тактового сигнала.
    logic clk;
    initial begin
        clk <= 0;
        forever #5 clk = ~clk;
    end

    // Массив интерфейсов.
    icon_intf intf [AG_NUM] (clk);

    generate
        for(genvar i = 0; i < AG_NUM; i++) begin
            initial begin
                uvm_resource_db#(virtual icon_intf)::set(
                    "uvm_test_top", $sformatf("vif_%0d", i), intf[i]);
            end
        end
    endgenerate

    initial begin
        uvm_resource_db#(int)::set("uvm_test_top", "ag_num", AG_NUM);
        run_test("icon_test");
    end

endmodule
