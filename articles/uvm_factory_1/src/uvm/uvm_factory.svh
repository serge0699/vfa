// Demystifying UVM: Фабрика, часть 2

// Базовый класс для всех proxy-классов типов.
// Handle данного типа используется для переда-
// чи указателей на ~uvm_component_registry~,
// параметризованных разными типами.
// См. uvm_registry.svh.
class uvm_object_wrapper;

    virtual function uvm_component create_component(
        string        name, 
        uvm_component parent
    ); 
        return null;
    endfunction

endclass

// Класс, каждый экземпляр которого предназначен
// для сохранения информации о конкретном переоп-
// ределении типа. Поле ~orig_type~ содержит ука-
// затель на proxy-объект оригинального типа, а
// поле ~ovrd_type~ содержит указатель на proxy-
// объект типа, на который переопределен ориги-
// нальный.
class uvm_factory_override;

    uvm_object_wrapper orig_type;
    uvm_object_wrapper ovrd_type;

    function new (
        uvm_object_wrapper orig_type,
        uvm_object_wrapper ovrd_type
    );
        this.orig_type = orig_type;
        this.ovrd_type = ovrd_type;
  endfunction

endclass

// Класс фабрики. Служит для создания компонентов и
// объектов, а также для хранения информации о пере-
// определении типов этих компонентов и объектов.
class uvm_factory;

    // Очередь, содержащая информацию о переопределениях
    // типов. При вызове ~set_type_override_by_type()~ в
    // очередь добавляется запись о переопредении, которая
    // является объектом типа ~uvm_factory_override~.
    protected uvm_factory_override m_type_overrides [$];

    // Метод создания компонента по предоставленному типу.
    // Тип предоставляется через аргумент ~requested_type~,
    // который имеет тип ~uvm_object_wrapper~. Через handle
    // данного типа можно передавать любой proxy-класс для ре-
    // гистрации. См. файл uvm_registry.svh.
    virtual function uvm_component create_component_by_type(
        uvm_object_wrapper requested_type,  
        string             name, 
        uvm_component      parent
    );

        // В методе производится поиск переопределений для
        // типа, указанного в proxy-классе ~requested_type~.
        // См. метод ~find_override_by_type()~. Метод возвра-
        // щает указатель на объект proxy-класса типа, кото-
        // рый дожен быть создан с учетом существующих пе-
        // реопределений. Далее вызывается метод этого клас-
        // са ~create_component()~, который возвращает ука-
        // затель на необходимый тип. Реализацию этого ме-
        // тода см. в файле uvm_registry.svh.
        requested_type = find_override_by_type(requested_type);
        return requested_type.create_component(name, parent);

    endfunction

    // Функция для переопределения типа, который
    // определяется proxy-классом ~original_type~,
    // на тип, который определяется proxy-классом
    // ~override_type~.
    virtual function void set_type_override_by_type(
        uvm_object_wrapper original_type,
        uvm_object_wrapper override_type
    );

        // Индикатор того, что для ~original_type~
        // уже существует запись о переопределении,
        // и она будет замещена, то есть создание
        // новой записи не требуется.
        bit replaced;

        // Итерирование через все записи о переопределениях
        // ~m_type_overrides~. Если уже существует запись о
        // переопределении ~original_type~, то производится
        // замена указателей на proxy-классы типов. Полю
        // ~replaced~ присваивается значение 1.
        foreach (m_type_overrides[index]) begin
            if (m_type_overrides[index].orig_type == original_type) begin
              replaced = 1;
              m_type_overrides[index].orig_type = original_type;
              m_type_overrides[index].ovrd_type = override_type; 
            end
        end

        // Если запись о переопределении ~original_type~
        // отсутсвует, то она создается и сохраняется в
        // очередь ~m_type_overrides~.
        if (!replaced) begin
            uvm_factory_override override;
            override = new(.orig_type(original_type),
                           .ovrd_type(override_type));
            m_type_overrides.push_back(override);
        end

    endfunction

    // Метод поиска переопределений для типа, который определяется
    // proxy-классом ~requested_type~. Реализует рекурсивный поиск
    // по очереди ~m_type_overrides~.
    virtual function uvm_object_wrapper find_override_by_type(
        uvm_object_wrapper requested_type
    );

        // Итерирование через все записи о переопределениях
        // ~m_type_overrides~. Если переопределенный тип в
        // записи соответствует запрашиваемому, то рекурсивно
        // вызывается ~find_override_by_type()~ для типа, на
        // который был переопределен запрашиваемый. Рекурсив-
        // ный поиск позволяет обрабатывать ситуации с мно-
        // жественными переопределениями, например, ~my_test~
        // переопределен на ~my_new_test~, а ~my_new_test~
        // переопределен на ~my_super_test~. В этом случае
        // при вызове my_test::type_id::create() будет соз-
        // дан объект типа ~my_super_test~. См. 5 пример в
        // файле tb_simple.sv.
        foreach (m_type_overrides[index]) begin
            if (m_type_overrides[index].orig_type == requested_type) begin 
                return find_override_by_type(m_type_overrides[index].ovrd_type);
            end
        end
  
        // Если для запрашиваемого типа не найдено пере-
        // определений, то возвращается запрашиваемый тип
        // "сам по себе".
        return requested_type;

    endfunction

endclass
