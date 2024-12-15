onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib temp_vi_opt

do {wave.do}

view wave
view structure
view signals

do {temp_vi.udo}

run -all

quit -force
