// Demystifying UVM: Фабрика, часть 2

// Тестовый пакет для демонстрации механизмов фабрики UVM.
package test_pkg;

    // Импорт авторского пакета UVM.
    import sc_uvm_pkg::*;

    // Подключение авторских макросов UVM.
    `include "uvm_object_defines.svh";

    // Базовый класс теста, содержит только
    // конструктор и метод ~print()~, который
    // выводит имя типа, то есть "base_test".
    // Метод ~get_type_name()~ определяется
    // при помощи макроса ~uvm_component_utils~.
    // Результатом вызова будет:
    // | # Hello from 'base_test' type!
    class base_test extends uvm_test;

        `uvm_component_utils(base_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void print();
            $display("Hello from '%s' type!", get_type_name());
        endfunction

    endclass

    // Класс теста, наследованного от базового.
    // Содержит конструктор и метод ~print()~,
    // который вызывает сначала реализацию
    // родительского класса, а потом выводит
    // "Hello world!". Результатом вызова будет:
    // | # Hello from 'extended_test_1' type!
    // | # Hello world!
    class extended_test_1 extends base_test;

        `uvm_component_utils(extended_test_1)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void print();
            super.print();
            $display("Hello world!");
        endfunction

    endclass

    // Класс теста ~extended_test_2~, который
    // наследован от класса ~extended_test_1~.
    // Содержит конструктор и метод ~print()~,
    // который вызывает сначала реализацию
    // родительского класса, а потом выводит
    // "Hello world!". Результатом вызова будет:
    // | # Hello from 'extended_test_1' type!
    // | # Hello world!
    // | # Another hello world!!
    class extended_test_2 extends extended_test_1;

        `uvm_component_utils(extended_test_2)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void print();
            super.print();
            $display("Another hello world!");
        endfunction

    endclass

endpackage
