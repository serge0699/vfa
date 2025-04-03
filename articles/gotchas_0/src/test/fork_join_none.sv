// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// Начало выполнения процессов fork-join_none.

module fork_join_none;

    // В данном блоке очередность вывода однозначно
    // определена:

    // Statement 1
    // Statement 2
    // Statement 3
    // Statement 4
    // Process 1

    // Процессы в fork-join_none начинают выполнение
    // совместно с первым потенциально блокирующим си-
    // муляцию выражением (wait(), @, # и т.п.) или пос-
    // ле завершения родительского процесса. В данном
    // примере вызов $display() после fork-join_none не
    // является потенциально блокирующим выражением, так
    // что вызов вывода в fork-join_none начинает выпол-
    // няться после завершения родительского initial, то
    // есть после выполнения всех $display() после него.
    // См. SystemVerilog IEEE Std 1800-2023 раздел 9.3.2.

    initial begin
        $display("Statement 1");
        fork
            $display("Process 1");
        join_none
        $display("Statement 2");
        $display("Statement 3");
        $display("Statement 4");
    end

endmodule
