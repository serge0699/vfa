// Demystifying UVM: Фабрика, часть 2

// Модуль для демонстрации создания компонентов UVM
// и переопределения их типов.
module tb_simple;

    // Импорт тестового пакета.
    // См. файл test_pkg.sv.
    import test_pkg::*;

    initial begin

        // Handle типа базового теста ~base_test~.
        base_test test;

        // Создание компонента типа базового теста ~base_test~ 
        // при помощи вызова ~base_test::type_id::create()~.
        // Возвращаемый методом указатель присваивается handle
        // базового типа, и производится вызов метода ~print()~.
        // Результатом вывода будет:
        // | # Hello from 'base_test' type!
        $display("\n0. No override:");
        test = base_test::type_id::create("test", null);
        test.print();

        // Создание компонента типа ~extended_test_1~, кото-
        // рый наследован от базового. Реализуется при по- 
        // мощи вызова ~extended_test_1::type_id::create()~,
        // Возвращаемый методом указатель присваивается handle
        // базового типа, и производится вызов метода ~print()~.
        // Handle базового типа указывает на объект наследован-
        // нного. При вызове метода через handle базового ти-
        // па будет вызвана реализация наследника, так как ме-
        // тод ~print()~ виртуальный.
        // Результатом вывода будет:
        // | # Hello from 'extended_test_1' type!
        // | # Hello world!
        $display("\n1. Upcast 'base_test' to 'extended_test_1:");
        test = extended_test_1::type_id::create("test", null);
        test.print();

        // Производится переопределение типа ~base_test~ на тип
        // ~extended_test_1~ при помощи вызова статического метода
        // ~base_test::type_id::set_type_override()~. После пере-
        // определения происходит создание компонента базового ти-
        // па ~base_test~, но вызов ~base_test::type_id::create()~
        // вернет указатель на объект типа ~extended_test_1~, так
        // как ранее этот тип был переопределен. При вызове метода
        // через handle базового типа будет вызвана реализация нас-
        // ледника, так как метод ~print()~ виртуальный.
        // Результатом вывода будет:
        // | # Hello from 'extended_test_1' type!
        // | # Hello world!
        $display("\n2. Override 'base_test' to 'extended_test_1':");
        base_test::type_id::set_type_override(extended_test_1::get_type());
        test = base_test::type_id::create("test", null);
        test.print();

        // Производится переопределение типа ~base_test~ на тип
        // ~extended_test_2~ при помощи вызова статического метода
        // ~base_test::type_id::set_type_override()~. Несмотря на
        // то, что ранее тип ~base_test~ был переопределен на тип
        // ~extended_test_1~, при создании компонента базового ти-
        // па при помощи ~base_test::type_id::create()~ будет воз-
        // вращен указатель на объект типа ~extended_test_2~, так
        // как 'выигрывает" последнее вызванное переопределение.
        // Тонкости реализации см. в файле ../uvm/uvm_factory.svh,
        // метод ~set_type_override_by_type()~.
        $display("\n3. Override 'base_test' to 'extended_test_2':");
        base_test::type_id::set_type_override(extended_test_2::get_type());
        test = base_test::type_id::create("test", null);
        test.print();

        // Производится переопределение типа ~extended_test_2~
        // на тип ~extended_test_1~. Таким образом, вызов
        // ~base_test::type_id::create()~ вернет указатель
        // на объект типа ~extended_test_1~, потому что при об-
        // работке запроса на создание фабрикой UVM сначала бу-
        // дет найдено переопределение с типа ~base_test~ на тип
        // ~extended_test_2~, а после будет выполнен поиск пере-
        // определений для ~extended_test_2~ и будет найдено пе-
        // реопределение на тип ~extended_test_1~. Тонкости ре-
        // ализации см. в файле ../uvm/uvm_factory.svh, метод
        // ~find_override_by_type()~.
        $display("\n4. Override 'extended_test_2' to 'extended_test_1':");
        extended_test_2::type_id::set_type_override(extended_test_1::get_type());
        test = base_test::type_id::create("test", null);
        test.print();

        $finish();

    end

endmodule
