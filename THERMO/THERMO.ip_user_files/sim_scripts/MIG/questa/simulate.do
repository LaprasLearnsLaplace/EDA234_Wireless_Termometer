onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib MIG_opt

do {wave.do}

view wave
view structure
view signals

do {MIG.udo}

run -all

quit -force
