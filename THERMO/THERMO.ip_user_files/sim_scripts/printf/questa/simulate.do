onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib printf_opt

do {wave.do}

view wave
view structure
view signals

do {printf.udo}

run -all

quit -force
