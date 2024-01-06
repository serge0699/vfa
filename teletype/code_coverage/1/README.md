```bash
vlog *.sv
vsim testbench -coverage -voptargs="+cover=s+/testbench/DUT" -do "run -a;"
```