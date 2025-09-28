// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// Совместный запуск последовательностей на множестве агентов.

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
    // В данном примере получает транзакцию и со
    // случайной задержкой информирует о ее завер-
    // шении. Не взаимодействует с интерфейсом.

    class icon_driver extends uvm_driver#(icon_seq_item);

        `uvm_component_utils(icon_driver)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task main_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);
                `uvm_info(get_name(), $sformatf("Got item: %s",
                    req.convert2string()), UVM_MEDIUM);
                #(1 * $urandom_range(10, 20));
                seq_item_port.item_done();
            end
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
    // создается их массив.

    // В main_phase() создается массив sequence,
    // каждая их которых запускается на соответ-
    // ствующем ей sequencer из agent.
    //
    // Обратите внимание на ~int j = i~.
    // Создание данной переменной необходимо, так
    // как выполнение ~seq[j].start(ag[j].sqr)~
    // произойдет совместно с выполнением wait fork
    // (см. пример fork_join_none.sv).

    // Без использования автоматической переменной
    // ~seq[ag_num]~ была бы запущена на sequencer
    // ~ag[ag_num].sqr~, что привело бы к ошибке
    // доступа к памяти, так как максимальный номер
    // agent в массиве равен ag_num-1. Почему sequence
    // была бы запущена на ~ag[ag_num].sqr~? - потому
    // что запуск бы произошел после итерирования сов-
    // местно с wait fork, а в этот момент времени
    // итератор уже равен ~ag_num~, то есть каждый
    // вызов ~seq[i].start(ag[i].sqr)~ выродился бы
    // в ~seq[ag_num].start(ag[ag_num].sqr)~.

    class icon_test extends uvm_test;

        `uvm_component_utils(icon_test)

        icon_agent ag  []; int ag_num;
        icon_seq   seq [];

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            void'(uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_num", ag_num));
            ag = new[ag_num];
            foreach(ag[i]) begin
                ag[i] = icon_agent::type_id::create(
                    $sformatf("ag_%0d", i), this);
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

// Модуль для запуска теста ~icon_test~.
// Количество агентов в примере равно 6.

module fork_join_seqs;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import icon_dv_pkg::*;

    initial begin
        uvm_resource_db#(int)::set("uvm_test_top", "ag_num", 6);
        run_test("icon_test");
    end

endmodule
