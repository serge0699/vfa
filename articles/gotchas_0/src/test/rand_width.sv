// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// Рандомизация переменных ширины более 32 бит.

// В данном примере переменная ~data~ имеет
// разрядность 64 бит. Функции $urandom() и
// $urandom_range() возвращают случайный
// unisgned int, разрядность которого 32 би-
// та. Так что рандомизация переменных ши-
// риной 32 бит за 1 вызов этих функций не-
// возможна (будет срандомизирована лишь
// младшая 32-битная часть).

// Для рандомизации переменных шириной более
// 32 бит можно использовать либо конкатена-
// цию $urandom()/$urandom_range(), либо фун-
// кцию std::randomize().

module rand_width;

    typedef bit [63:0] data_t;

    initial begin
        data_t data;
        repeat(5) begin
            data = $urandom();               $display("%h", data);
            data = {$urandom(), $urandom()}; $display("%h", data);
            void'(std::randomize(data));     $display("%h", data);
        end
    end

endmodule
