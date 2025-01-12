// Demystifying UVM: Фабрика, часть 2

// Пакет с классами компонента, фабрики,
// coreservice и proxy-классом для ре-
// гистрации типа. Импортируется в тес-
// товом пакете. См. файл test_pkg.sv.
package sc_uvm_pkg;

    `include "uvm_component.svh"
    `include "uvm_test.svh"
    `include "uvm_factory.svh"
    `include "uvm_coreservice.svh"
    `include "uvm_registry.svh"

endpackage
