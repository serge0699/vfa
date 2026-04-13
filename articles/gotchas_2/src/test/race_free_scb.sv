// SystemVerilog Gotchas, Tips and Tricks, часть 3.

// Обработка гонок в параллельных потоках транзакций.

`ifndef AG_M_NUM
    `define AG_M_NUM 2
`endif

`ifndef AG_S_NUM
    `define AG_S_NUM 2
`endif

package race_free_scb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Определение типа для адреса.

    typedef bit [$clog2(`AG_S_NUM)-1:0] addr_t;

    // Элемент последовательности для работы с интерконнектом.

    class icon_seq_item extends uvm_sequence_item;

        `uvm_object_utils(icon_seq_item)

        rand addr_t addr;
        rand int    data;

        function new(string name = "");
            super.new(name);
        endfunction

        virtual function string convert2string();
            string str = $sformatf(
                "Addr: %h, Data: %h", addr, data);
            return str;
        endfunction

    endclass

    // Монитор для работы с интерконнектом.
    // В данном примере не взаимодейстует с интерфейсом.
    // Генерирует случайные транзакции с настраиваемой задержкой.

    class icon_monitor extends uvm_monitor;

        `uvm_component_utils(icon_monitor)

        int delay;
        uvm_analysis_port#(icon_seq_item) ap;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            if(!uvm_resource_db#(int)::read_by_name(
                get_full_name(), "delay", delay))
                begin
                    `uvm_fatal(get_full_name(), "Can't get 'delay'!");
                end
            ap = new("ap", this);
        endfunction

        virtual task main_phase(uvm_phase phase);
            icon_seq_item t;
            forever begin
                #(delay * 1ns);
                t = icon_seq_item::type_id::create("t");
                void'(t.randomize());
                `uvm_info("ITEMINFO", $sformatf(
                    "Got item! %s", t.convert2string()), UVM_HIGH);
                ap.write(t);
            end
        endtask

    endclass

    // Агент для работы с интерконнектом.
    // В данном примере содержит монитор и порт анали-
    // за для иерархического проброса TLM-соединений.

    class icon_agent extends uvm_agent;

        `uvm_component_utils(icon_agent)

        uvm_analysis_port#(icon_seq_item) ap;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        icon_monitor mon;

        virtual function void build_phase(uvm_phase phase);
            mon = icon_monitor::type_id::create("mon", this);
            ap = new("ap", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            mon.ap.connect(ap);
        endfunction

    endclass

    // Предиктор интерконнекта.
    // Получает параллельные потоки транзакци от
    // master, синхронизирует их и вычисляет ре-
    // ференсные потоки для slave транзакций.
    // Далее см. комментарии в коде класса.

    class icon_predictor extends uvm_component;

        `uvm_component_utils(icon_predictor)

        // Количества агентов.

        int ag_m_num;
        int ag_s_num;

        // Массивы TLM экспортов и FIFO.
        // Служат для получения и хранения master-транзакций.

        uvm_analysis_export  #(icon_seq_item) ae    [];
        uvm_tlm_analysis_fifo#(icon_seq_item) afifo [];

        // Массив TLM портов анализа.
        // Служит для отправки референсных slave-транзакций.

        uvm_analysis_port#(icon_seq_item) ap [];

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        // В ~build_phase()~ производится получение количеств
        // агентов и создание TLM-компонентов.

        virtual function void build_phase(uvm_phase phase);
            // Получение количеств агентов.
            if(!uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_m_num", ag_m_num))
                begin
                    `uvm_fatal("NOAGMNUM", "Can't get 'ag_m_num'!");
                end
            if(!uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_s_num", ag_s_num))
                begin
                    `uvm_fatal("NOAGSNUM", "Can't get 'ag_s_num'!");
                end
            // Инициализация массивов.
            ae    = new[ag_m_num];
            afifo = new[ag_m_num];
            ap    = new[ag_s_num];
            // Создание TLM-компонентов.
            foreach(ae[i]   ) ae   [i] = new($sformatf("ae_%0d",    i), this);
            foreach(afifo[i]) afifo[i] = new($sformatf("afifo_%0d", i), this);
            foreach(ap[i]   ) ap   [i] = new($sformatf("ap_%0d",    i), this);
        endfunction

        // В ~connect_phase()~ экспорт подключается к
        // соответствующему FIFO анализа.

        virtual function void connect_phase(uvm_phase phase);
            foreach(ae[i]) ae[i].connect(afifo[i].analysis_export);
        endfunction

        //
        // Алгоритм обработки параллельных потоков транзакций:
        //
        //  +---------------------------------------------------------------------------+
        //  | 1. wait_any_fifo()           | Ожидание попадания транзакции хотя бы в    |
        //  |                              | один буфер FIFO анализа.                   |
        //  +---------------------------------------------------------------------------+
        //  | 2. uvm_wait_for_nba_region() | Реализованный в UVM метод ожидания NBA ре- |
        //  |                              | гиона. Гарантирует конкретный момент вре-  |
        //  |                              | мени попадание транзакций со всех монито-  |
        //  |                              | ров в соответствующие им буферы FIFO.      |
        //  +---------------------------------------------------------------------------+
        //  | 3. proc_all_fifo()           | Обработка транзакций во всех буферах FIFO. |
        //  +---------------------------------------------------------------------------+
        //

        virtual task main_phase(uvm_phase phase);
            forever begin
                wait_any_fifo();
                uvm_wait_for_nba_region();
                proc_all_fifo();
            end
        endtask

        // Ожидание попадание транзакций хотя бы в один FIFO анализа
        // реализовано через совместный запуск процессов и общий эвент.
        // Ссылки по теме:
        //   - https://serge0699.github.io/vfa/articles/gotchas_0
        //   - https://stackoverflow.com/a/40309973/31658479

        virtual task wait_any_fifo();
            fork begin
                event any_fifo;
                foreach(afifo[i]) begin
                    automatic int j = i;
                    fork begin
                        icon_seq_item tmp;
                        afifo[j].peek(tmp);
                        -> any_fifo;
                    end join_none
                end
                @(any_fifo);
                disable fork;
            end join
        endtask

        // Метод обработки транзакций во всех FIFO
        // в конкретный момент времени. Вызывается
        // после ~uvm_wait_for_nba_region()~. См.
        // код выше.

        virtual function void proc_all_fifo();
        
            // Вспомогательные массивы.

            icon_seq_item items   [];
            bit           results [];
            icon_seq_item slaves  [][$];

            items   = new[ag_m_num];
            results = new[ag_m_num];
            slaves  = new[ag_s_num];

            // Итерирование по всем FIFO, начиная с 0
            // индекса. Переменная ~results[i]~ хранит
            // флаг наличия транзакции в i-ом FIFO.
            // Переменная ~items[i]~ хранит указатель
            // на транзакцию в i-ом FIFO.

            for(int i = 0; i < ag_m_num; i++) begin
                `ifdef VERILATOR
                    icon_seq_item tmp;
                    results[i] = afifo[i].try_get(tmp);
                    items[i] = tmp;
                `else
                    results[i] = afifo[i].try_get(items[i]);
                `endif
            end

            //
            // Итерирование по результатам получения
            // транзакций из FIFO. Если транзакция была
            // получена из FIFO и адрес в диапазоне до-
            // пустимых, то транзакция отправляется в
            // очередь для соответствующего slave.
            //
            // NOTE: Арбитраж производится непосредствен-
            //       но в этом цикле. Обрабатываются сна-
            //       чала FIFO с меньшим индексом.
            //

            for(int i = 0; i < ag_m_num; i++) begin
                if(results[i]) begin
                    if(items[i].addr inside {[0:ag_s_num-1]}) begin
                        slaves[items[i].addr].push_back(items[i]);
                    end
                end
            end

            // Вывод информации о сформированном потоке
            // транзакций для каждого slave.

            begin
                foreach(slaves[i]) begin
                    if(slaves[i].size()) begin
                        uvm_default_table_printer.print_array_header(
                            $sformatf("Slave[%0h]", i), slaves[i].size(), "int"
                        );
                        begin
                            icon_seq_item its [$]; 
                            its = slaves[i];
                            foreach(its[j]) begin
                                uvm_default_table_printer.print_field_int(
                                    $sformatf("data[%0d]", j), its[j].data, 32
                                );
                            end
                        end
                        uvm_default_table_printer.print_array_footer(slaves[i].size());
                    end
                end
                `uvm_info("SLAVEINFO", $sformatf("\n\nData for slaves at current moment:\n%s",
                    uvm_default_table_printer.emit()), UVM_HIGH);
            end

            // Для каждого slave отправляем поток
            // транзакций в соответствующий ему
            // порт анализа.

            begin
                for(int i = 0; i < ag_s_num; i++) begin
                    icon_seq_item its [$];
                    its = slaves[i];
                    foreach(its[j]) begin
                        ap[i].write(its[j]);
                    end
                end
            end
        
        endfunction

    endclass

    // Компаратор интерконнекта.
    // Сравнивает входящие потоки slave транзакций
    // от предиктора и мониторов. В данном примере
    // производится только получение и вывод, срав-
    // нение не производится. Далее см. комментарии
    // в коде класса.

    class icon_comparator extends uvm_component;

        `uvm_component_utils(icon_comparator)

        // Количество slave агентов.

        int ag_s_num;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        // FIFO и подключенные к ним экспорты с реальными
        // (_r) данными от slave-мониторов.

        uvm_analysis_export  #(icon_seq_item) ae_r    [];
        uvm_tlm_analysis_fifo#(icon_seq_item) afifo_r [];

        // FIFO и подключенные к ним экспорты с ожидаемыми
        // (_e) данными от slave-мониторов.

        uvm_analysis_export  #(icon_seq_item) ae_e    [];
        uvm_tlm_analysis_fifo#(icon_seq_item) afifo_e [];

        // В ~build_phase()~ производится получение количества
        // агентов и создание TLM-компонентов.

        virtual function void build_phase(uvm_phase phase);
            // Получение количества агентов.
            if(!uvm_resource_db#(int)::read_by_name(get_full_name(), "ag_s_num", ag_s_num))
                `uvm_fatal("NOAGSNUM", "Can't get 'ag_s_num'!");
            // Инициализация массивов.
            ae_r    = new[ag_s_num];
            afifo_r = new[ag_s_num];
            ae_e    = new[ag_s_num];
            afifo_e = new[ag_s_num];
            // Создание TLM-компонентов.
            foreach(ae_r[i]   ) ae_r   [i] = new($sformatf("ae_r_%0d",    i), this);
            foreach(afifo_r[i]) afifo_r[i] = new($sformatf("afifo_r_%0d", i), this);
            foreach(ae_e[i]   ) ae_e   [i] = new($sformatf("ae_e_%0d",    i), this);
            foreach(afifo_e[i]) afifo_e[i] = new($sformatf("afifo_e_%0d", i), this);
        endfunction
        
        // В ~connect_phase()~ экспорты подключаются к
        // соответствующим FIFO анализа.

        virtual function void connect_phase(uvm_phase phase);
            foreach(ae_r[i]) ae_r[i].connect(afifo_r[i].analysis_export);
            foreach(ae_r[i]) ae_e[i].connect(afifo_e[i].analysis_export);
        endfunction

        // Запуск параллельных циклов обработки FIFO.

        virtual task main_phase(uvm_phase phase);
            foreach(afifo_r[i]) begin
                automatic int j = i;
                fork
                    process_fifo(j);
                join_none
            end
        endtask

        // Задачи обработки FIFO.
        // В данной реализации производится получение
        // транзакций из FIFO и вывод их содержимого.
        // Сравнение не производится. 

        virtual task process_fifo(int i);
            icon_seq_item t_r, t_e;
            forever begin
                afifo_r[i].get(t_r);
                afifo_e[i].get(t_e);
                `uvm_info("ITEMINFO", $sformatf(
                    "Got item real from FIFO[%0d]! %s",
                        i, t_r.convert2string()), UVM_HIGH);
                `uvm_info("ITEMINFO", $sformatf(
                    "Got item expd from FIFO[%0d]! %s",
                        i, t_e.convert2string()), UVM_HIGH);
            end
        endtask

    endclass

    // Scoreboard интерконнекта.
    // Содержит предиктор и компаратор.
    // Создает их, конфигурирует и соединяет.

    class icon_scoreboard extends uvm_scoreboard;

        `uvm_component_utils(icon_scoreboard)

        // Количества агентов.

        int ag_m_num;
        int ag_s_num;

        // Предиктор и компаратор.

        icon_predictor  prd;
        icon_comparator cmp;

        // Экспорты.

        uvm_analysis_export#(icon_seq_item) ae_m [];
        uvm_analysis_export#(icon_seq_item) ae_s [];

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            // Получение количеств агентов.
            if(!uvm_resource_db#(int)::read_by_name(get_full_name(), "ag_m_num", ag_m_num))
                `uvm_fatal("NOAGMNUM", "Can't get 'ag_m_num'!");
            if(!uvm_resource_db#(int)::read_by_name(get_full_name(), "ag_s_num", ag_s_num))
                `uvm_fatal("NOAGSNUM", "Can't get 'ag_s_num'!");
            // Отправка количеств агентов во вложенные компоненты.
            uvm_resource_db#(int)::set({get_full_name(), ".prd"}, "ag_m_num", ag_m_num);
            uvm_resource_db#(int)::set({get_full_name(), ".prd"}, "ag_s_num", ag_s_num);
            uvm_resource_db#(int)::set({get_full_name(), ".cmp"}, "ag_s_num", ag_s_num);
            // Инициализация массивов.
            ae_m = new[ag_m_num];
            ae_s = new[ag_s_num];
            // Создание TLM-компонентов.
            foreach(ae_m[i]) ae_m[i] = new($sformatf("ae_m_%0d", i), this);
            foreach(ae_s[i]) ae_s[i] = new($sformatf("ae_s_%0d", i), this);
            // Создание предиктора и компаратора.
            prd = icon_predictor ::type_id::create("prd", this);
            cmp = icon_comparator::type_id::create("cmp", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            // Master -> предиктор.
            foreach(ae_m[i])
                ae_m[i].connect(prd.ae[i]);
            // Предиктор -> компаратор.
            foreach(prd.ap[i])
                prd.ap[i].connect(cmp.ae_e[i]);
            // Slave -> компаратор.
            foreach(ae_s[i])
                ae_s[i].connect(cmp.ae_r[i]);
        endfunction

    endclass

    //
    // Класс теста интерконнекта.
    // Содержит массивы агентов и табло.
    //
    // Создает агентов и табло, конфигурирует
    // табло количествами агентов. Соединяет
    // TLM-порты монитора с экспортами табло.
    //

    class icon_test extends uvm_test;

        `uvm_component_utils(icon_test)

        // Количества агентов.

        int ag_m_num;
        int ag_s_num;

        // Массивы агентов.

        icon_agent ag_m [];
        icon_agent ag_s [];

        // Табло (scoreboard).

        icon_scoreboard scb;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            // Получение количеств агентов.
            if(!uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_m_num", ag_m_num))
                begin
                    `uvm_fatal(get_full_name(), "Can't get 'ag_m_num'!");
                end
            if(!uvm_resource_db#(int)::read_by_name(
                get_full_name(), "ag_s_num", ag_s_num))
                begin
                    `uvm_fatal(get_full_name(), "Can't get 'ag_s_num'!");
                end
            // Создание агентов.
            ag_m = new[ag_m_num];
            ag_s = new[ag_s_num];
            foreach(ag_m[i]) begin
                ag_m[i] = icon_agent::type_id::create(
                    $sformatf("ag_m_%0d", i), this);
                uvm_resource_db#(int)::set({get_full_name(),
                    $sformatf(".ag_m_%0d.mon", i)}, "delay", i + 1);
            end
            foreach(ag_s[i]) begin
                ag_s[i] = icon_agent::type_id::create(
                    $sformatf("ag_s_%0d", i), this);
                uvm_resource_db#(int)::set({get_full_name(),
                    $sformatf(".ag_s_%0d.mon", i)}, "delay", i + 1);
            end
            // Конфигурация табло и его создание.
            uvm_resource_db#(int)::set({get_full_name(), ".scb"}, "ag_m_num", ag_m_num);
            uvm_resource_db#(int)::set({get_full_name(), ".scb"}, "ag_s_num", ag_s_num);
            scb = icon_scoreboard::type_id::create("scb", this);
        endfunction

        // Соединение мониторов агентов с табло.
        // Для master и slave.

        virtual function void connect_phase(uvm_phase phase);
            foreach(ag_m[i]) ag_m[i].ap.connect(scb.ae_m[i]);
            foreach(ag_s[i]) ag_s[i].ap.connect(scb.ae_s[i]);
        endfunction

        // В данном примере последовательностей не запускается.
        // Фаза длится 1000ns, позволяя мониторам генерировать
        // транзакции, а табло их обрабатывать. 

        virtual task main_phase(uvm_phase phase);
            phase.raise_objection(this);
            #100ns;
            phase.drop_objection(this);
        endtask

    endclass

endpackage

// Модуль для запуска тестов.

module race_free_scb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import race_free_scb_pkg::*;

    // Запуск теста.

    initial begin
        uvm_resource_db#(int)::set("uvm_test_top", "ag_m_num", `AG_M_NUM);
        uvm_resource_db#(int)::set("uvm_test_top", "ag_s_num", `AG_S_NUM);
        run_test();
    end

endmodule
