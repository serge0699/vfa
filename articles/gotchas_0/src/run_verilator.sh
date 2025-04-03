# Запуск симуляции.
mkdir -p ./out/verilator
verilator --binary ./test/$1.sv --trace --trace-params \
    --trace-structs -top-module $1 -Mdir out/verilator
out/verilator/V$1
