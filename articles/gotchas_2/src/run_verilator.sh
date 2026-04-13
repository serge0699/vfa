# Переменные.
out=./out/verilator
uvm="--depth 1 --branch uvm-1.2 https://github.com/chipsalliance/uvm-verilator.git"

nowarn="-Wno-UNSIGNED -Wno-DECLFILENAME -Wno-VARHIDDEN -Wno-WIDTHEXPAND \
          -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-IGNOREDRETURN"

# Выходная директория.
mkdir -p ${out}

# Выбор версии UVM.
if [ ! -d "${out}/uvm" ]; then
  git clone ${uvm} ${out}/uvm
fi

# Компиляция.
verilator ${out}/uvm/src/uvm_pkg.sv ./test/$1.sv \
  +incdir+${out}/uvm/src +incdir+./test \
    --binary --Mdir ${out} --error-limit 5 -j $(nproc) --threads $(nproc) \
      -Wall --timescale 1ns/1ps +incdir+${out}/uvm/src +define+UVM_NO_DPI \
        $nowarn -top $1 $3

# Запуск.
${out}/V$1 $2
