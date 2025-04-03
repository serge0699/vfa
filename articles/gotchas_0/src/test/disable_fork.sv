// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// Завершение потоков через disable fork.

module disable_fork;

    // Задача запускает процессы 1 и 2.
    // После завершения процесса 1 задача
    // завершится, а процесс 2 продолжит
    // выполняться.

    task run_processes();
        fork
            repeat( 3) #1 $display("Process 1");
            repeat(20) #1 $display("Process 2");
        join_any
        $display("-- Exit run_processes()");
    endtask

    // Блок ниже после завершения задачи
    // ~run_processes()~ запускает совместно
    // 2 процесса. Когда один из них завер-
    // шается, выполняется disable fork,
    // который принудительно завершит как
    // процесс 4, так и процесс 2, который
    // был порожден задачей ~run_processes()~.
    // См. SystemVerilog IEEE Std 1800-2023
    // раздел 9.6.3.

    initial begin
        run_processes();
        fork begin
            fork
                repeat( 3) #1 $display("Process 3");
                repeat(10) #1 $display("Process 4");
            join_any
            $display("-- Exit fork and disable it");
            disable fork;
        end join
        repeat(3) #1 $display("Process 5");
        $finish();
    end

endmodule
