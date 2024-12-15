onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib FIFO_8to8_opt

do {wave.do}

view wave
view structure
view signals

do {FIFO_8to8.udo}

run -all

quit -force
