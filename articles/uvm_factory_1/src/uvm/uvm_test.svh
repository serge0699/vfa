// Класс, от которого наследуются пользовательские
// классы теста (test).
class uvm_test extends uvm_component;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
