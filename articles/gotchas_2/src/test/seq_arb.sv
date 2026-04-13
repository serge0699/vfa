// SystemVerilog Gotchas, Tips and Tricks, часть 3.

// UVM и арбитраж последовательностей.

package seq_arb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Элемент последовательности.
    // Содержит данные ~data~.

    class seq_item extends uvm_sequence_item;

        `uvm_object_utils(seq_item)

        rand int data;

        function new(string name = "");
            super.new(name);
        endfunction

        virtual function string convert2string();
            string str = $sformatf("data: %h", data);
            return str;
        endfunction

    endclass

    // Последовательность.

    class seq extends uvm_sequence#(seq_item);

        `uvm_object_utils(seq)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            repeat(10) begin
                req = seq_item::type_id::create("req");
                start_item(req);
                rand_item(req);
                finish_item(req);
            end
        endtask

        virtual function void rand_item(seq_item t);
            void'(t.randomize());
        endfunction

    endclass

    // Последовательность шума.
    // Каждый бит данных в логической единице

    class seq_noise extends seq;

        `uvm_object_utils(seq_noise)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual function void rand_item(seq_item t);
            void'(t.randomize() with {data == '1;});
        endfunction

    endclass

    // Секвенсер.
    // Содержит метод пользовательского арбитража.
    // Пользовательский арбитраж первые 5 раз возвращает
    // последовательность, стоящую последней в очереди на
    // арбитраж. 

    class sequencer extends uvm_sequencer#(seq_item);

        `uvm_component_utils(sequencer)

        protected int random_cnt;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function integer user_priority_arbitration(integer avail_sequences [$]);
            if(random_cnt == 4) begin
                set_arbitration(UVM_SEQ_ARB_WEIGHTED);
            end
            random_cnt++;
            return avail_sequences[avail_sequences[avail_sequences.size()-1]];
        endfunction

    endclass

    // Драйвер.
    // В данном примере получает транзакцию и со
    // случайной задержкой информирует о ее завер-
    // шении. Не взаимодействует с интерфейсом.

    class driver extends uvm_driver#(seq_item);

        `uvm_component_utils(driver)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task main_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);
                `uvm_info("ITEMINFO", $sformatf(
                    "Got item! %s", req.convert2string()), UVM_HIGH);
                 #(1 * $urandom_range(10, 20));
                seq_item_port.item_done();
            end
        endtask

    endclass

    // Агент. Инкапсулирует секвенсер и драйвер.
    // Монитор в данном примере не используется.

    class agent extends uvm_agent;

        `uvm_component_utils(agent)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        sequencer sqr;
        driver    drv;

        virtual function void build_phase(uvm_phase phase);
            sqr = sequencer::type_id::create("sqr", this);
            drv = driver::type_id::create("drv", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction

    endclass

    // Класс теста. Инкапсулирует в себе агента
    // и последовательность.

    // В main_phase() создается и запускается
    // последовательность.

    class test extends uvm_test;

        `uvm_component_utils(test)

        // Агент.
        agent ag;

        // Последовательность.
        seq_arb_pkg::seq seq;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            ag = agent::type_id::create("ag", this);
        endfunction

        virtual task main_phase(uvm_phase phase);
            phase.raise_objection(this);
            seq = seq_arb_pkg::seq::type_id::create("seq");
            seq.start(ag.sqr);
            phase.drop_objection(this);
        endtask

    endclass

    // Класс теста с последовательностью шума.

    // В main_phase() последовательность шума
    // запускается совместно с основной после-
    // довательностью.

    class test_noise extends test;

        `uvm_component_utils(test_noise)

        // Последовательность шума.
        seq_arb_pkg::seq_noise seq_noise;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task main_phase(uvm_phase phase);
            fork
                super.main_phase(phase);
            join_none
            phase.raise_objection(this);
            seq_noise = seq_arb_pkg::seq_noise::type_id::create("seq_noise");
            seq_noise.start(ag.sqr);
            phase.drop_objection(this);
        endtask

    endclass

    // Класс теста с последовательностью шума,
    // а также настраиваемыми схемой арбитража
    // секвенсера и приоритетом для последова-
    // тельности шума. См. метод ~get_settings()~.

    // В main_phase() последовательность шума
    // запускается совместно с основной после-
    // довательностью.

    class test_noise_custom extends test;

        `uvm_component_utils(test_noise_custom)

        // Последовательность шума.
        seq_arb_pkg::seq_noise seq_noise;

        // Схема арбитража секвенсера.
        uvm_sequencer_arb_mode sqr_arb_mode = UVM_SEQ_ARB_FIFO;

        // Приоритет для последовательности шума.
        int seq_noise_priority = -1;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task main_phase(uvm_phase phase);
            // Получение настроек из командной строки.
            get_settings();
            // Настройка схемы арбитража секвенсера.
            ag.sqr.set_arbitration(sqr_arb_mode);
            fork
                super.main_phase(phase);
            join_none
            phase.raise_objection(this);
            seq_noise = seq_arb_pkg::seq_noise::type_id::create("seq_noise");
            // Запуск последовательности шума с приоритетом.
            // Приоритет также можно было настроить через
            // ~seq_noise.set_priority()~.
            seq_noise.start(ag.sqr, .this_priority(seq_noise_priority));
            phase.drop_objection(this);
        endtask

        virtual function void get_settings();
            string sqr_arb_mode_str;
            string seq_noise_priority_str;
            // Схема арбитража.
            if($value$plusargs("sqr_arb_mode=%0s", sqr_arb_mode_str)) begin
                uvm_enum_wrapper#(uvm_sequencer_arb_mode)::from_name(
                    sqr_arb_mode_str,
                    sqr_arb_mode
                );
            end
            // Get priority form commandline.
            if($value$plusargs("seq_noise_priority=%0s", seq_noise_priority_str)) begin
                seq_noise_priority = seq_noise_priority_str.atoi();
            end
        endfunction

    endclass

endpackage

// Модуль для запуска тестов.

module seq_arb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import seq_arb_pkg::*;

    // Запуск теста.
    initial begin
        run_test();
    end

endmodule
