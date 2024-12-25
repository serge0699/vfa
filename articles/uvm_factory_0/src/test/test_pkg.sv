// Demystifying UVM: Фабрика, часть 1

// Тестовый пакет для демонстрации параметризации
// классов типами.
package test_pkg;

    // Класс ~my_wrapper~ параметризован типом ~T~
    // и содержит метод ~create_some_class()~, который
    // создает объект типа ~T~ и возвращает указатель
    // на него.
    class my_wrapper #(type T);
    
        static function T create_some_class();
            T cl;
            cl = new();
            return cl;
        endfunction

    endclass

    // Класс ~my_awesome_class~, который содержит
    // виртуальный метод ~print()~.
    class my_awesome_class;

        virtual function void print();
            $display("Hello from 'my_awesome_class'!");
        endfunction

    endclass

    // Класс ~my_new_awesome_class~, который наследуется
    // от ~my_awesome_class~ и переопределяет реализацию
    // метода ~print()~ базового класса (родителя).
    class my_new_awesome_class extends my_awesome_class;

        virtual function void print();
            $display("Hello from 'my_new_awesome_class'!");
        endfunction

    endclass

endpackage
