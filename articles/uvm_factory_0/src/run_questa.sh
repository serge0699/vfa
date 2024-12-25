mkdir -p ./out/questa
vlog ./test/test_pkg.sv ./test/$1.sv \
    -work ./out/work -l ./out/questa/compile.log
vsim -c $1 -do "run -a; quit -f" -work ./out/work -l ./out/questa/sim.log
