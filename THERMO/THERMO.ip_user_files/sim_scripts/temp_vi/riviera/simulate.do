onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+temp_vi -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.temp_vi xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {temp_vi.udo}

run -all

endsim

quit -force
