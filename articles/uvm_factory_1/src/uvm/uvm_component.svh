// Demystifying UVM: Фабрика, часть 2

// Класс компонента, от которого наследуются
// классы, представляющие собой структуру ве-
// рификационного окружения. Например driver,
// monitor, agent, sequencer и т.д.
class uvm_component;

    // Конструктор. В UVM его реализация не является
    // пустой и будет дополнена в следующих разборах.
    // Для данного же разбора достаточно пустой реа-
    // лизации.
    function new(string name, uvm_component parent);
    
    endfunction

endclass
