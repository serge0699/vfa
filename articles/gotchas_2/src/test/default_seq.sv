// SystemVerilog Gotchas, Tips and Tricks, часть 3.

// UVM и последовательность по умолчанию.

`include "seq_arb.sv"

package default_seq_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import seq_arb_pkg::*;

    // Последовательность с автоматическими objection.
    // Данная последовательность отличается от базовой (из ~seq_arb_pkg~)
    // тем, что при запуске автоматически поднимает objection (до метода
    // body()) и снимает objection при завершении (после метода body()).

    class seq_auto_obj extends seq;

        `uvm_object_utils(seq_auto_obj)

        function new(string name = "");
            super.new(name);
            set_automatic_phase_objection(1);
        endfunction

    endclass

    // Тест с добавление последовательности шума в качестве последователь-
    // ности по умолчанию. Последовательность будет запущена на секвенсере
    // в main_phase() совместно с базовой, которая вручную запускается
    // через start() (см. класс ~test~ в seq_arb.sv).
    //
    // Идентичного функционала можно добиться через командную строку, за-
    // пустив ~test~ и передав настройку:
    //
    // +uvm_set_default_sequence=uvm_test_top.ag.sqr,main_phase,seq_noise

    class test_default_noise extends test;

        `uvm_component_utils(test_default_noise)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            uvm_resource_db #(uvm_object_wrapper)::set(
                {get_full_name(), ".ag.sqr.main_phase"}, "default_sequence",
                    seq_noise::type_id::get());
        endfunction
        
    endclass

    // Тест без ручного запуска через start() базовой последовательности.
    // Если попытаться запустить базовую последовательность через настройку:
    //
    // +uvm_set_default_sequence=uvm_test_top.ag.sqr,main_phase,seq
    //
    // то последовательность не будет выполнена, так как objection не будет
    // поднят. Для того, чтобы последовательность автоматически поднимала
    // objection, необходимо активировать это свойство при помощи вызова
    // метода set_automatic_phase_objection(1) (см. ~seq_auto_obj~).
    // Теперь можно запустить ее через:
    //
    // +uvm_set_default_sequence=uvm_test_top.ag.sqr,main_phase,seq_auto_obj

    class test_no_base extends test;

        `uvm_component_utils(test_no_base)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task main_phase(uvm_phase phase);
            return;
        endtask
        
    endclass

endpackage

// Модуль для запуска тестов.

module default_seq;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import seq_arb_pkg::*;
    import default_seq_pkg::*;

    // Запуск теста.
    initial begin
        run_test();
    end

endmodule
