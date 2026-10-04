#!/bin/bash

# Обработка режима симуляции. Аргументы режима
# собираются в позиционные параметры (POSIX-аналог
# массива), поэтому скрипт работает и через sh.
top=$1
if [ "$2" = "-gui" ]; then
  set -- -gui -voptargs="+acc" -do "add wave *"
else
  set -- -c
  quit="quit -f"
fi

# Запуск симуляции.
mkdir -p ./out/questa
vlog ./test/$top.sv -work ./out/work -l ./out/questa/compile.log && \
vsim $top "$@" -do "run -a; ${quit}" -work ./out/work -l ./out/questa/sim.log
