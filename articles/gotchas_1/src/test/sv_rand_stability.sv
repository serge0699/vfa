// SystemVerilog Gotchas, Tips and Tricks, часть 2.

// SystemVerilog и стабильность рандомизации.

module sv_rand_stability;

    class dummy;
        rand int data;
    endclass

    initial begin

        // d - handle;
        // p - переменная процесса;
        // s - строка для получения состояния RNG процесса.
        dummy d; process p; string s;

        // Инициализация переменной процесса.
        p = process::self();

        // Рандомизация двух чисел.
        $display("%8h", $urandom());
        $display("%8h", $urandom());

        // Если через командную строку передан аргумент
        // +save_randstate, то сохраняется состояние RNG
        // потока в переменную ~s~.
        if($test$plusargs("save_randstate")) begin
            s = p.get_randstate();
        end

        // Если через командную строку передан аргумент
        // +create_dummy, то создается объекта типа ~dummy~.
        if($test$plusargs("create_dummy")) begin
            $display("Created dummy!");
            d = new();
        end

        // Если через командную строку передан аргумент
        // +create_thread, то создается динамический поток.
        if($test$plusargs("create_thread")) begin
            fork begin
                $display("Created thread!");
                $urandom();
             end join
        end

        // Если через командную строку передан аргумент
        // +save_randstate, то состояние RNG потока вос-
        // станавливется из переменной ~s~ при помощи
        // метода set_randstate().
        if($test$plusargs("save_randstate")) begin
            p.set_randstate(s);
        end

        // Рандомизация двух чисел.
        $display("%8h", $urandom());
        $display("%8h", $urandom());

        // Завершение симуляции.
        $finish();

    end

endmodule
