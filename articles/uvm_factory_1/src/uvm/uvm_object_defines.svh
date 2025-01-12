// Demystifying UVM: Фабрика, часть 2

// Макросы для регистрации типа компонента.

// Данный макрос должен быть "вызван" для
// каждого из типов компонентов, которые
// планируются к использованию в верифика-
// ционном окружении. Пример вызова см. в
// файле test_pkg.sv.
// Инкапсулирует в себе "вызовы" макросов
// ~m_uvm_component_registry_internal~
// и ~m_uvm_get_type_name_func~, кото-
// рые определены ниже.
`define uvm_component_utils(T) \
   `m_uvm_component_registry_internal(T,T) \
   `m_uvm_get_type_name_func(T) \

// Данный макрос определяет proxy-класс реги-
// страции для типа ~T~ с уникальным строчным 
// названием ~S~. При "вызове" данного макроса
// в макросе ~uvm_component_utils~ уникаль-
// строчное название совпадает с названием типа.
// Обратите внимание, что название экземпляра
// proxy-класса ~type_id~. То есть, при созда-
// нии компонента через ~type_id::create()~
// происходит обращение к статическому методу
// ~create()~ экземляра ~type_id~, что, в свою
// очередь, приводит к вызову метода фабрики
// ~create_component_by_type()~. См. файл
// ~uvm_registry.svh~.
`define m_uvm_component_registry_internal(T,S) \
   typedef uvm_component_registry #(T,`"S`") type_id; \
   static function type_id get_type(); \
      return type_id::get(); \
   endfunction

// Данный макрос создает статическое поле
// ~type_name~, содержащее название типа
// класса в виде строки, а также метод
// ~get_type_name()~, возвращающий это
// название типа.
`define m_uvm_get_type_name_func(T) \
   const static string type_name = `"T`"; \
   virtual function string get_type_name (); \
      return type_name; \
   endfunction

// "Вызов" ~`uvm_component_utils(my_test)~ "раскроется" в:
//
// | typedef uvm_component_registry #(my_test,"my_test") type_id;
// |
// | static function type_id get_type();
// |     return type_id::get();
// | endfunction
// |
// | const static string type_name = "my_test";
// |
// | virtual function string get_type_name ();
// |     return type_name;
// | endfunction
//
// Пример "вызова":
//
// | class my_test extends uvm_component;
// | 
// |     `uvm_component_utils(my_test)
// | 
// |      function new(string name, uvm_component parent);
// |          super.new(name, parent);
// |      endfunction
// | 
// | endclass