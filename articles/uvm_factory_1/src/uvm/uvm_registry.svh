// Demystifying UVM: Фабрика, часть 2

// Proxy-класс для регистрации типа объекта.
// Я является singleton классом, который су-
// ществует в единственном экземпляре в ходе
// симуляции. Указатель на единственный эк-
// земпляр можно получить при помощи ~get()~.
// Тип наследуется от ~uvm_object_wrapper~.
// См. файл uvm_factory.svh.
class uvm_component_registry #(
    type   T     = uvm_component,
    string Tname = "<unknown>"
) extends uvm_object_wrapper;

    // Объявление пользовательского типа исключительно для
    // удобства использования.
    // Вместо ~uvm_component_registry #(T, Tname)~ можно
    // будет использовать ~this_type~.
    typedef uvm_component_registry #(T, Tname) this_type;

    // Метод создания компонента типа ~T~, которым
    // параметризован тип ~uvm_component_registry~.
    virtual function uvm_component create_component(
        string        name,
        uvm_component parent
    );
        T obj;
        obj = new(name, parent);
        return obj;
    endfunction

	// Защищенный указатель на единственный
	// экземпляр типа ~this_type~.
    local static this_type me = get();

	// Функция получения указателя на единствен-
	// ный экземпляр типа ~this_type~.
    static function this_type get();
        if (me == null) begin
            me = new();
        end
        return me;
    endfunction

    // Метод создания компонента. В методе вызывается
    // метод фабрики ~create_component_by_type()~, вы-
    // зов которого приводит к поиску возможных пере-
    // определений типа ~this_type~. См. реализацию
    // метода в uvm_factory.sv.
    static function T create(
        string        name,
        uvm_component parent
    );
        uvm_component obj;
        uvm_coreservice_t cs = uvm_coreservice_t::get();
        uvm_factory factory = cs.get_factory();
        obj = factory.create_component_by_type(get(), name, parent);
        $cast(create, obj);
    endfunction

    // Метод переопределения типа ~this_type~ типом,
    // на который указывает переменная ~override_type~.
    // Обратите внимание, что новый тип передается че-
    // рез handle типа ~uvm_object_wrapper~, от котого
    // наследуются все proxy-классы для регистрации
    // типа ~uvm_component_registry~. См. файл
    // uvm_object_defines.svh.
    static function void set_type_override(
        uvm_object_wrapper override_type
    );
        uvm_coreservice_t cs = uvm_coreservice_t::get();
        uvm_factory factory = cs.get_factory();                                          
        factory.set_type_override_by_type(get(), override_type);
    endfunction

endclass
