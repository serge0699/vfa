```bash
vlog *.sv
```
Стандартный:

```bash
vsim testbench -coverage -voptargs="+cover=sb+/testbench/DUT" -do "run -a;"
```

С базой данных:

```bash
vsim testbench -coverage -voptargs="+cover=sb+/testbench/DUT" -do "run -a; coverage save cov.ucdb;"
vsim -viewcov cov.ucdb
```

С текстовым отчетом:

```bash
vsim testbench -coverage -voptargs="+cover=sb+/testbench/DUT" -do "run -a; coverage report -details -file cov.txt;
nano cov.txt
```

С HTML отчетом:

```bash
vsim testbench -coverage -voptargs="+cover=sb+/testbench/DUT" -do "run -a; coverage report -html -details -htmldir htmlcov;"
firefox htmlcov/index.html
```