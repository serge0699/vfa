# Обработка режима симуляции.
if [ "$3" == "-gui" ]; then
  args=(-gui -voptargs="+acc")
else
  args=-c
  quit="quit -f"
fi

# Выходная директория.
mkdir -p ./out/questa

# Выбор версии UVM.
if [ -z "${QUESTA_HOME}" ]; then
  echo "Variable $QUESTA_HOME is not set!"
  exit 1
fi
vmap mtiUvm $QUESTA_HOME/uvm-1.2

# Компиляция, элаборация и симуляция.
vlog ./test/$1.sv -work ./out/work -l ./out/questa/compile.log $3 && \
vsim $1 "${args[@]}" $2 -do "run -a; ${quit}" -work ./out/work \
    -l ./out/questa/sim.log
