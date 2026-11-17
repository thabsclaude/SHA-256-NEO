open_project {C:/Users/tchip/FPGA Bitcoin Miner/FPGA Bitcoin Miner.xpr}
add_files -norecurse {C:/Users/tchip/FPGA Bitcoin Miner/rtl/sha256_compress.v}
add_files -fileset sim_1 -norecurse {C:/Users/tchip/FPGA Bitcoin Miner/testbench/sha256_compress_tb.v}
set_property top sha256_compress_tb [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -mode behavioral
run all
