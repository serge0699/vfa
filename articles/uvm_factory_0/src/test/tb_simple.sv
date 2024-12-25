// Demystifying UVM: Фабрика, часть 1

// Модуль для демонстрации демонстрации параметризации
// классов типами.
module tb_simple;

    // Импорт тестового пакета.
    // См. файл test_pkg.sv.
    import test_pkg::*;

    initial begin

        // Handle типа базового класса ~my_awesome_class~.
        my_awesome_class cl;

        // Данный выхов ~create_some_class()~ вернет указатель
        // на объект типа ~my_awesome_class~. См. реализацию
        // метода в файле test_pkg.sv.
        // Результатом вызова ~print()~ будет:
        // | # Hello from 'my_awesome_class'!
        cl = my_wrapper#(my_awesome_class)::create_some_class();
        cl.print();

        // Данный выхов ~create_some_class()~ вернет указатель
        // на объект типа ~my_new_awesome_class~. То есть handle
        // базового класса будет указывать на объект типа, нас-
        // ледованного от базового. Вызов ~print()~ приведет к
        // вызову реализации наследованного класса, так как ме-
        // тод является виртуальным.
        // Результатом вызова ~print()~ будет:
        // | # Hello from 'my_new_awesome_class'!
        cl = my_wrapper#(my_new_awesome_class)::create_some_class();
        cl.print();

        $finish();

    end

endmodule
