# Обработка режима симуляции.
if [ "$3" == "-gui" ]; then
  args=(-gui -voptargs="+acc")
else
  args=-c
  quit="quit -f"
fi

# Выходная директория.
mkdir -p ./out/questa

# Компиляция, элаборация и симуляция.
vlog ./test/$1.sv -work ./out/work -l ./out/questa/compile.log && \
vsim $1 "${args[@]}" $2 -do "run -a; ${quit}" -work ./out/work \
    -l ./out/questa/sim.log
