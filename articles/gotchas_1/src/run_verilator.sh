# Выходная директория.
mkdir -p ./out/verilator

# Запуск симуляции.
verilator --binary ./test/$1.sv --trace --trace-params \
    --trace-structs -top-module $1 $2 -Mdir out/verilator
out/verilator/V$1
