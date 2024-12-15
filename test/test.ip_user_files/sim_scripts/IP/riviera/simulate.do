onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+FIFO_8to8 -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.FIFO_8to8 xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {FIFO_8to8.udo}

run -all

endsim

quit -force
