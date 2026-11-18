# Reproducible implementation flow for the uart_miner top-level design.
# It records machine-generated reports under reports/generated/ and generates
# a bitstream only when all setup constraints are met.

set project_dir [file normalize [file join [file dirname [info script]] ..]]
set report_dir [file join $project_dir reports generated]
file mkdir $report_dir

open_project [file join $project_dir {FPGA Bitcoin Miner.xpr}]
set_property top uart_miner [get_filesets sources_1]

# Register any RTL or testbench files that are not yet in the project.
foreach f [glob -nocomplain -directory [file join $project_dir rtl] *.v] {
    if {[llength [get_files -quiet -all [file tail $f]]] == 0} {
        add_files -norecurse -fileset sources_1 [list $f]
    }
}
foreach f [glob -nocomplain -directory [file join $project_dir testbench] *.v] {
    if {[llength [get_files -quiet -all [file tail $f]]] == 0} {
        add_files -norecurse -fileset sim_1 [list $f]
    }
}

# The blinker constraint file belongs to a different top-level design.
# Match by name: the project path contains a space, which breaks path patterns.
set_property IS_ENABLED false [get_files -all {*led_blinker.xdc}]
set_property IS_ENABLED true  [get_files -all {*uart_miner.xdc}]
update_compile_order -fileset sources_1

reset_run synth_1
reset_run impl_1
launch_runs synth_1 -jobs 6
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis did not complete successfully."
}

launch_runs impl_1 -to_step route_design -jobs 6
wait_on_run impl_1
if {![string match "route_design Complete*" [get_property STATUS [get_runs impl_1]]]} {
    error "Implementation did not complete successfully."
}

open_run impl_1
report_utilization -file [file join $report_dir uart_miner_utilization.rpt]
report_timing_summary -max_paths 10 -warn_on_violation \
    -file [file join $report_dir uart_miner_timing_summary.rpt]
report_drc -file [file join $report_dir uart_miner_drc.rpt]

set worst_path [get_timing_paths -setup -max_paths 1]
set wns [get_property SLACK $worst_path]
puts "UART_MINER_WNS_NS=$wns"

if {$wns < 0.0} {
    error "Routed setup timing failed (WNS = $wns ns); no bitstream generated."
}

write_bitstream -force [file join $report_dir uart_miner_timing_clean.bit]
puts "Timing clean bitstream written to reports/generated/."
