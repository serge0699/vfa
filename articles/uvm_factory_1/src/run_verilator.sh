mkdir -p ./out/verilator
verilator --binary ./uvm/sc_uvm_pkg.sv ./test/test_pkg.sv ./test/$1.sv \
    +incdir+./uvm/ --trace --trace-params --trace-structs -top-module $1 \
        -Mdir out/verilator
out/verilator/V$1