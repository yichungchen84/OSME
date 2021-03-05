#!/usr/bin/tclsh

# Process node
set ::env(PROCESS) "130"

# Rules for metal fill
set ::env(FILL_CONFIG) "$::env(PDK_DIR)/fill.json"

# Set the TIEHI/TIELO cells
# These are used in yosys synthesis to avoid logical 1/0's in the netlist
set ::env(TIEHI_CELL_AND_PORT) "sky130_fd_sc_hd__conb_1 HI"
set ::env(TIELO_CELL_AND_PORT) "sky130_fd_sc_hd__conb_1 LO"

# Blackbox verilog file
# List all standard cells and cells yosys should treat as blackboxes here
set ::env(BLACKBOX_V_FILE) "$::env(PDK_DIR)/sky130_fd_sc_hd.blackbox.v"

# Yosys mapping files
set ::env(LATCH_MAP_FILE) "$::env(PDK_DIR)/cells_latch_hd.v"
set ::env(CLKGATE_MAP_FILE) "$::env(PDK_DIR)/cells_clkgate_hd.v"
set ::env(BLACKBOX_MAP_TCL) "$::env(PDK_DIR)/blackbox_map.tcl"

# Placement site for core cells
# This can be found in the technology lef
set ::env(PLACE_SITE) "unithd"

# Skywater130 information for generating DEF tracks
set ::env(TRACKS_INFO_FILE) "$::env(PDK_DIR)/tracks_hd.info"

# Skywater130 information for tlef, merged lef, and cdl
set ::env(TECH_LEF) "$::env(PDK_DIR)/lef/sky130_fd_sc_hd.tlef"
set ::env(SC_LEF) "$::env(PDK_DIR)/lef/sky130_fd_sc_hd_merged.lef"
set ::env(CDL_FILE) "$::env(PDK_DIR)/sky130hd.cdl"

# Netgen LVS setup for skywater130
set ::env(NETGEN_LVS) "$::env(PDK_DIR)/sky130_setup.tcl"

# Skywater130 information for spice
set ::env(SP_FILE) \
    "$::env(PDK_DIR)/sp/sky130hd.sp \
    $::env(PDK_DIR)/sp/sky130_fd_pr__nfet_01v8.pm3.sp \
    $::env(PDK_DIR)/sp/sky130_fd_pr__pfet_01v8_hvt.pm3.sp \
    $::env(PDK_DIR)/sp/sky130_fd_pr__nfet_01v8.pm3.sp"

# Skywater130 information for liberty and gds
set ::env(LIB_FILES) "$::env(PDK_DIR)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
if {[info exists ADDITIONAL_LIBS]} {
    append ::env(LIB_FILES) " " "$ADDITIONAL_LIBS"
}
set ::env(GDS_FILES) [glob $::env(PDK_DIR)/gds/*.gds]
if {[info exists ADDITIONAL_GDS_FILES]} {
    append ::env(GDS_FILES) " " "$ADDITIONAL_GDS_FILES"
}

# Endcap and Welltie cells
set ::env(TAPCELL_TCL) "$::env(PDK_DIR)/tapcell.tcl"

# IO Pin fix margin
set ::env(IO_PIN_MARGIN) "70"

# Layer to use for parasitics estimations
set ::env(WIRE_RC_LAYER) "met3"

# KLayout technology file
set ::env(KLAYOUT_TECH_FILE) "$::env(PDK_DIR)/sky130hd.lyt"
set ::env(KLAYOUT_TECH_LAYER_FILE) "$::env(PDK_DIR)/sky130hd.lyp"
set ::env(KLAYOUT_TECH_DRC_FILE) "$::env(PDK_DIR)/sky130hd.lydrc"
set ::env(KLAYOUT_LVS_FILE) "$::env(PDK_DIR)/sky130hd.lylvs"

# Dont use cells to ease congestion
# Specify at least one filler cell if none

# The *probe* are for inserting probe points and have metal shapes
# on all layers.
# *lpflow* cells are for multi-power domains
set ::env(DONT_USE_CELLS) \
    "sky130_fd_sc_hd__probe_p_8 sky130_fd_sc_hd__probec_p_8 \
    sky130_fd_sc_hd__lpflow_bleeder_1 \
    sky130_fd_sc_hd__lpflow_clkbufkapwr_1 \
    sky130_fd_sc_hd__lpflow_clkbufkapwr_16 \
    sky130_fd_sc_hd__lpflow_clkbufkapwr_2 \
    sky130_fd_sc_hd__lpflow_clkbufkapwr_4 \
    sky130_fd_sc_hd__lpflow_clkbufkapwr_8 \
    sky130_fd_sc_hd__lpflow_clkinvkapwr_1 \
    sky130_fd_sc_hd__lpflow_clkinvkapwr_16 \
    sky130_fd_sc_hd__lpflow_clkinvkapwr_2 \
    sky130_fd_sc_hd__lpflow_clkinvkapwr_4 \
    sky130_fd_sc_hd__lpflow_clkinvkapwr_8 \
    sky130_fd_sc_hd__lpflow_decapkapwr_12 \
    sky130_fd_sc_hd__lpflow_decapkapwr_3 \
    sky130_fd_sc_hd__lpflow_decapkapwr_4 \
    sky130_fd_sc_hd__lpflow_decapkapwr_6 \
    sky130_fd_sc_hd__lpflow_decapkapwr_8 \
    sky130_fd_sc_hd__lpflow_inputiso0n_1 \
    sky130_fd_sc_hd__lpflow_inputiso0p_1 \
    sky130_fd_sc_hd__lpflow_inputiso1n_1 \
    sky130_fd_sc_hd__lpflow_inputiso1p_1 \
    sky130_fd_sc_hd__lpflow_inputisolatch_1 \
    sky130_fd_sc_hd__lpflow_isobufsrc_1 \
    sky130_fd_sc_hd__lpflow_isobufsrc_16 \
    sky130_fd_sc_hd__lpflow_isobufsrc_2 \
    sky130_fd_sc_hd__lpflow_isobufsrc_4 \
    sky130_fd_sc_hd__lpflow_isobufsrc_8 \
    sky130_fd_sc_hd__lpflow_isobufsrckapwr_16 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_hl_isowell_tap_1 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_hl_isowell_tap_2 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_hl_isowell_tap_4 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_isowell_4 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_isowell_tap_1 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_isowell_tap_2 \
    sky130_fd_sc_hd__lpflow_lsbuf_lh_isowell_tap_4"

# Define ABC driver and load
set ::env(ABC_DRIVER_CELL) "sky130_fd_sc_hd__buf_1"
set ::env(ABC_LOAD_IN_FF) "5"
#export ABC_CLOCK_PERIOD_IN_PS = 10

# TritonCTS configuration
set ::env(CTS_TECH_DIR) "$::env(PDK_DIR)/tritonCTShd"

# Define default PDN config
set ::env(PDN_CFG) "$::env(PDK_DIR)/pdn.cfg"

# Define fastRoute tcl
set ::env(FASTROUTE_TCL) "$::env(PDK_DIR)/fastroute.tcl"

# Template definition for power grid analysis
# set ::env(TEMPLATE_PGA_CFG) "./platforms/sky130/template_pga.cfg" 
# not there

# Define Hold Buffer
set ::env(HOLD_BUF_CELL) "sky130_fd_sc_hd__buf_1"

# IO Placer pin layers
set ::env(IO_PLACER_H) "4"
set ::env(IO_PLACER_V) "3"

# keep with gf
set ::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) "4"
set ::env(CELL_PAD_IN_SITES_DETAIL_PLACEMENT) "2"

# Define fill cells
set ::env(FILL_CELLS) "sky130_fd_sc_hd__fill_1 \
    sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_4 \
    sky130_fd_sc_hd__fill_8"

# resizer repair_long_wires -max_length
set ::env(MAX_WIRE_LENGTH) "21000"

