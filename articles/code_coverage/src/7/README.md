```bash
vlog *.sv
```
Без покрытия:

```bash
time vsim -batch testbench -do "run -a;"
```

С покрытием:

```bash
time vsim -batch testbench -coverage -voptargs="+cover=bs+/testbench/DUT" -do "run -a;"
vsim -viewcov cov.ucdb
```