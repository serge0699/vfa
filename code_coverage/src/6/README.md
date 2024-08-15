```bash
vlog *.sv
vsim testbench -coverage -voptargs="+acc +cover=f+/testbench/DUT" -do "run -a;"
```