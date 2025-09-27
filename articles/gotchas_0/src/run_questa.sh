# Обработка режима симуляции.
if [ "$2" == "-gui" ]; then
  args=(-gui -voptargs="+acc" -do "add wave *")
else
  args=-c
  quit="quit -f"
fi

# Запуск симуляции.
mkdir -p ./out/questa
vlog ./test/$1.sv -work ./out/work -l ./out/questa/compile.log && \
vsim $1 "${args[@]}" -do "run -a; ${quit}" -work ./out/work -l ./out/questa/sim.log
