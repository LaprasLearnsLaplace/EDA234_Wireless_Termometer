onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xpm -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.FIFO_8to8 xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {FIFO_8to8.udo}

run -all

quit -force
