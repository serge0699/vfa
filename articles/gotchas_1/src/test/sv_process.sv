// SystemVerilog Gotchas, Tips and Tricks, часть 2.

// SystemVerilog process.

module sv_process;

    timeunit 1ns;
    timeprecision 100ps;

    class seq;

        string name;

        function new(string name);
            this.name = name;
        endfunction

        virtual task start(int delay);
            $display("%5.1f %s started!", $realtime(), name);
            for(int i = 0; i < delay; i++) begin
                #1ns; $display("%5.1f %s %0d tick!", $realtime(), name, i);
            end
            $display("%5.1f %s ended!", $realtime(), name);
        endtask

    endclass

    // Метод для получения задержки из командной строки.
    function automatic int get_delay();
        void'($value$plusargs("delay=%0d", get_delay));
    endfunction

    initial begin

        // Handle процессов для последовательностей.
        process seq_0_p;
        process seq_1_p;

        // Handle последовательностей.
        seq seq_0;
        seq seq_1;
        
        // Совместное создание и запуск последовательностей.
        // Обратите внимание на инициализацию handle процессов
        // при помощи метода self(). Ниже в коде мы будем вза-
        // имодействовать с этими handle.
        fork
            begin
                seq_0_p = process::self();
                seq_0 = new("seq_0");
                seq_0.start(10);
            end
            begin
                seq_1_p = process::self();
                seq_1 = new("seq_1");
                seq_1.start(5);
            end
        join_none

        // Ожидание 500ps.
        #500ps;

        // Вывод статуса для ~seq_0~ и ~seq_1~.
        // Ожидаемый результат: WAITING.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | WAITING means the process is waiting in a blocking statement.
        // В этот момент времени процесса ждут в блокирующем выражении #1. 
        $display("%5.1f seq_0 status: %p", $realtime(), seq_0_p.status());
        $display("%5.1f seq_1 status: %p", $realtime(), seq_1_p.status());

        // Остановка процесса для ~seq_0~.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | Suspending a process in the WAITING state shall cause 
        // | the process to be desensitized to the event expression,
        // | wait condition, or delay expiration on which it is
        // | blocked.
        seq_0_p.suspend();

        // Принудительное завершение процесса для ~seq_1().
        seq_1_p.kill();
        
        // Вывод статуса для ~seq_0~.
        // Ожидаемый результат: SUSPENDED.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | SUSPENDED means the process is stopped awaiting a resume.
        $display("%5.1f seq_0 status: %p", $realtime(), seq_0_p.status());

        // Вывод статуса для ~seq_1~.
        // Ожидаемый результат: KILLED.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | KILLED means the process was forcibly terminated
        // | (via kill() or disable (see 9.6.2)).
        $display("%5.1f seq_1 status: %p", $realtime(), seq_1_p.status());

        // Ожидание.
        #(1ps * get_delay());

        // Запуск остановленного ранее процесса.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | Calling resume() on a process that was suspended while
        // | in the WAITING state shall resensitize the process to
        // | the event expression or to wait for the wait condition
        // | to become true or for the delay to expire.
        seq_0_p.resume();

        // Ожидание завершения процесса.
        seq_0_p.await();

        // Вывод статуса.
        // Ожидаемый результат: FINISHED.
        // Согласно разделу 9.7 SystemVerilog IEEE Std 1800-2023:
        // | FINISHED means the process terminated normally.
        $display("%5.1f seq_0 status: %p", $realtime(), seq_0_p.status());

        $finish();

    end

endmodule
