// SystemVerilog Gotchas, Tips and Tricks, часть 1.

// Индексация данных при упаковке.

// При упаковке данных в SystemVerilog часто
// можно столкнуться с тем, что переменные,
// которые определяют интервал бит, должны
// быть compile-time или elaboration-time
// константами. То есть нет возможности на-
// писать, например, конструкцию:
// | for(int i = 0; i < 8; i = i + 1) begin
// |     word[i] = data[(i+1)*8-1:i*8];
// | end

// Для упаковки данных в SystemVerilog можно
// использовать streaming operator и indexed
// part-select. Примеры представлены в моду-
// ле ниже.

module data_packing;

    byte    data [];
    longint word;

    initial begin

        // Создание массива байт.
        data = new[8]('{8'hfa, 8'hde, 8'hca, 8'hfe,
                        8'hde, 8'had, 8'hbe, 8'hef});

        // Упаковка при помощи streaming operator.
        // См. SystemVerilog IEEE Std 1800-2023 раздел 11.4.14.
        word = {>>{data}};
        $display("word: %h", word);
        word = {<<8{data}};
        $display("word: %h", word);

        // Упаковка при помощи indexed part-select.
        // См. SystemVerilog IEEE Std 1800-2023 раздел 11.5.1.
        foreach(data[i]) word[64-8*(i+1)+:8] = data[i];
        $display("word: %h", word);
        foreach(data[i]) word[8*i+:8] = data[i];
        $display("word: %h", word);

    end

endmodule
