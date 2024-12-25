// Demystifying UVM: 0. Фабрика

// Singleton класс, предоставляющий доступ к
// основным сервисам UVM. В том числе к фабрике.
class uvm_coreservice_t;

	// Защищенный указатель на единственный
	// экземпляр типа ~uvm_coreservice_t~.
	local static uvm_coreservice_t inst;

	// Функция получения указателя на единствен-
	// ный экземпляр типа ~uvm_coreservice_t~.
	static function uvm_coreservice_t get();
		if(inst == null) begin
			inst = new();
        end
		return inst;
	endfunction

	// Защищенный указатель на единственный
	// экземпляр типа ~uvm_factory~. Дан-
	// ный класс предоставляет доступ к фаб-
	// рике.
    local uvm_factory factory;

	// Функция получения указателя на единствен-
	// ный экземпляр типа ~uvm_factory~.
    virtual function uvm_factory get_factory();
	    if(factory == null) begin
	    	factory = new();
	    end 
		return factory;
	endfunction

endclass
