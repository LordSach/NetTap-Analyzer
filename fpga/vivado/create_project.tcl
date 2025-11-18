create_project nettap_analyzer ./vivado -part xc7z020clg400-1
set_property board_part digilentinc.com:pynq-z2:part0:1.0 [current_project]


add_files [glob ../rtl/**/*.sv]
add_files [glob ../constraints/*.xdc]


update_compile_order -fileset sources_1


puts "Vivado project generated successfully"
