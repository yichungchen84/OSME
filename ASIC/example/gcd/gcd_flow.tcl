#!/usr/bin/tclsh

####todo list 03/04/2021
## 1. time
####

# set home directory (the same folder of the flow script)
set ::env(PROJ_HOME_DIR) [file dirname [file normalize [info script]]]

# config.tcl for general design information
source "$::env(PROJ_HOME_DIR)/config.tcl"

# pdk_config.tcl for PDK information, no need to change
source "$::env(PROJ_HOME_DIR)/pdk_config.tcl"

# runtime_config.tcl for design specific parameters
source "$::env(PROJ_HOME_DIR)/runtime_config.tcl"

# SHELL = /bin/bash -o pipefail
# TIME_CMD = /usr/bin/time -f "%Eelapsed %PCPU %MmemKB"
# set TIME_CMD "/usr/bin/time -f \"%Eelapsed %PCPU %MmemKB\""
# set OPENROAD_CMD "openroad -no_init -exit"

# grab info of CPU cores
set fp [open "/proc/cpuinfo" r]
set ::env(NUM_CORES) [regexp -all -line {^processor\s} [read $fp]]
close $fp

# prepare folders
exec mkdir -p $::env(RESULTS_DIR) $::env(LOG_DIR) $::env(REPORTS_DIR) $::env(OBJECTS_DIR)

# Utility to print tool version information
#-------------------------------------------------------------------------------
exec yosys -V > $::env(LOG_DIR)/versions.txt
exec echo openroad `openroad -version` >> $::env(LOG_DIR)/versions.txt
exec klayout -zz -v >> $::env(LOG_DIR)/versions.txt

# Pre-process Lefs
# ==============================================================================

# Modify lef files for TritonRoute
exec $::env(UTILS_DIR)/mergeLef.py --inputLef $::env(TECH_LEF) $::env(SC_LEF) \
    --outputLef $::env(OBJECTS_DIR)/merged_spacing.lef

# Pre-process libraries
# ==============================================================================

# Create temporary Liberty files which have the proper dont_use properties set
# For use with Yosys and ABC
# .SECONDEXPANSION:
# $(DONT_USE_LIBS): $$(filter %$$(@F),$(LIB_FILES))
append ::env(DONT_USE_LIBS) "$::env(OBJECTS_DIR)/lib" "/" [file tail $::env(LIB_FILES)]
append ::env(DONT_USE_SC_LIB) "$::env(OBJECTS_DIR)/lib" "/" [file tail $::env(LIB_FILES)]
exec mkdir -p $::env(OBJECTS_DIR)/lib
exec $::env(UTILS_DIR)/markDontUse.py -p $::env(DONT_USE_CELLS) -i $::env(LIB_FILES) \
    -o $::env(DONT_USE_LIBS)

# Pre-process KLayout tech
# ==============================================================================
#  $(OBJECTS_DIR)/klayout.lyt: $(KLAYOUT_TECH_FILE)
exec sed "/OR_DEFAULT/d" $::env(TECH_LEF) > $::env(OBJECTS_DIR)/klayout_tech.lef
lappend klayout_item "$::env(OBJECTS_DIR)/klayout_tech.lef"
lappend klayout_item "$::env(SC_LEF)"
lappend klayout_piece
foreach item $klayout_item {
    lappend klayout_piece <lef-files>[file normalize $item]</lef-files>
    }
exec sed "s,<lef-files>.*</lef-files>,$klayout_piece,g" $::env(KLAYOUT_TECH_FILE) > $::env(OBJECTS_DIR)/klayout.lyt

# # Create Macro wrappers (if necessary)
# # ==============================================================================
# WRAP_CFG = $(PLATFORM_DIR)/wrapper.cfg

# export TCLLIBPATH := util/cell-veneer $(TCLLIBPATH)
# $(WRAPPED_LEFS):
# 	mkdir -p $(OBJECTS_DIR)/lef $(OBJECTS_DIR)/def
# 	util/cell-veneer/wrap.tcl -cfg $(WRAP_CFG) -macro $(filter %$(notdir $(@:_mod.lef=.lef)),$(WRAP_LEFS))
# 	mv $(notdir $@) $@
# 	mv $(notdir $(@:lef=def)) $(dir $@)../def/$(notdir $(@:lef=def))

# $(WRAPPED_LIBS):
# 	mkdir -p $(OBJECTS_DIR)/lib
# 	sed 's/library(\(.*\))/library(\1_mod)/g' $(filter %$(notdir $(@:_mod.lib=.lib)),$(WRAP_LIBS)) | sed 's/cell(\(.*\))/cell(\1_mod)/g' > $@


# ==============================================================================
#  ______   ___   _ _____ _   _ _____ ____ ___ ____
# / ___\ \ / / \ | |_   _| | | | ____/ ___|_ _/ ___|
# \___ \\ V /|  \| | | | | |_| |  _| \___ \| |\___ \
#  ___) || | | |\  | | | |  _  | |___ ___) | | ___) |
# |____/ |_| |_| \_| |_| |_| |_|_____|____/___|____/
#
# ==============================================================================

# Synthesis
exec yosys -c $::env(SCRIPTS_DIR)/synth.tcl \
    |& tee >&@stdout $::env(LOG_DIR)/1_1_yosys.log

exec cp $::env(RESULTS_DIR)/1_1_yosys.v $::env(RESULTS_DIR)/1_synth.v

exec cp $::env(SDC_FILE) $::env(RESULTS_DIR)/1_synth.sdc

# clean_synth:
# 	rm -f  $(RESULTS_DIR)/1_*.v $(RESULTS_DIR)/1_synth.sdc
# 	rm -f  $(REPORTS_DIR)/synth_*
# 	rm -f  $(LOG_DIR)/1_*
# 	rm -rf _tmp_yosys-abc-*


# ==============================================================================
#  _____ _     ___   ___  ____  ____  _        _    _   _
# |  ___| |   / _ \ / _ \|  _ \|  _ \| |      / \  | \ | |
# | |_  | |  | | | | | | | |_) | |_) | |     / _ \ |  \| |
# |  _| | |__| |_| | |_| |  _ <|  __/| |___ / ___ \| |\  |
# |_|   |_____\___/ \___/|_| \_\_|   |_____/_/   \_\_| \_|
#
# ==============================================================================


# STEP 1: Translate verilog to def
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/floorplan.tcl -metrics $::env(LOG_DIR)/2_1_floorplan.json |& tee >&@stdout $::env(LOG_DIR)/2_1_floorplan.log

# STEP 2: IO Placement (random)
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/io_placement_random.tcl -metrics $::env(LOG_DIR)/2_2_floorplan_io.json |& tee >&@stdout $::env(LOG_DIR)/2_2_floorplan_io.log

# STEP 3: Timing Driven Mixed Sized Placement
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/tdms_place.tcl -metrics $::env(LOG_DIR)/2_3_tdms.json |& tee >&@stdout $::env(LOG_DIR)/2_3_tdms_place.log
exec $::env(UTILS_DIR)/fixIoPins.py --inputDef $::env(RESULTS_DIR)/2_3_floorplan_tdms.def --outputDef $::env(RESULTS_DIR)/2_3_floorplan_tdms.def --margin $::env(IO_PIN_MARGIN)

# STEP 4: Macro Placement
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/macro_place.tcl -metrics $::env(LOG_DIR)/2_4_mplace.json |& tee >&@stdout $::env(LOG_DIR)/2_4_mplace.log

# STEP 5: Tapcell and Welltie insertion
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/tapcell.tcl -metrics $::env(LOG_DIR)/2_5_tapcell.json |& tee >&@stdout $::env(LOG_DIR)/2_5_tapcell.log

# STEP 6: PDN generation
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/pdn.tcl -metrics $::env(LOG_DIR)/2_6_pdn.json |& tee >&@stdout $::env(LOG_DIR)/2_6_pdn.log

exec cp $::env(RESULTS_DIR)/2_6_floorplan_pdn.def $::env(RESULTS_DIR)/2_floorplan.def

# clean_floorplan:
# 	rm -f $(RESULTS_DIR)/2_*floorplan*.def $(RESULTS_DIR)/2_floorplan.sdc
# 	rm -f $(REPORTS_DIR)/2_*
# 	rm -f $(LOG_DIR)/2_*


# ==============================================================================
#  ____  _        _    ____ _____
# |  _ \| |      / \  / ___| ____|
# | |_) | |     / _ \| |   |  _|
# |  __/| |___ / ___ \ |___| |___
# |_|   |_____/_/   \_\____|_____|
#
# ==============================================================================

# STEP 1: Global placement + IO placement (not random)
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/global_place.tcl -metrics $::env(LOG_DIR)/3_1_place_gp.json |& tee >&@stdout $::env(LOG_DIR)/3_1_place_gp.log

# STEP 2: IO placement (non-random)
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/io_placement.tcl -metrics $::env(LOG_DIR)/3_2_place_iop.json |& tee >&@stdout $::env(LOG_DIR)/3_2_place_iop.log

# STEP 3: Resizing & Buffering
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/resize.tcl -metrics $::env(LOG_DIR)/3_3_resizer.json |& tee >&@stdout $::env(LOG_DIR)/3_3_resizer.log

# clean_resize:
# exec rm -f $::env(RESULTS_DIR)/3_3_place_resized.def

# STEP 4: Detail placement
#-------------------------------------------------------------------------------
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/detail_place.tcl -metrics $::env(LOG_DIR)/3_4_opendp.json |& tee >&@stdout $::env(LOG_DIR)/3_4_opendp.log

exec cp $::env(RESULTS_DIR)/3_4_place_dp.def $::env(RESULTS_DIR)/3_place.def

exec cp $::env(RESULTS_DIR)/2_floorplan.sdc $::env(RESULTS_DIR)/3_place.sdc

exec xvfb-run -a klayout -z \
    -rd input_layout=$::env(RESULTS_DIR)/3_place.def \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rd tech_layer=$::env(KLAYOUT_TECH_LAYER_FILE) \
    -rm $::env(UTILS_DIR)/scsKlayout.py \
    |& tee >&@stdout $::env(LOG_DIR)/3_klayout_def.log

# # Clean Targets
# #-------------------------------------------------------------------------------
# clean_place:
# 	rm -f $(RESULTS_DIR)/3_*place*.def
# 	rm -f $(RESULTS_DIR)/3_place.sdc
# 	rm -f $(REPORTS_DIR)/3_*
# 	rm -f $(LOG_DIR)/3_*


# ==============================================================================
#   ____ _____ ____
#  / ___|_   _/ ___|
# | |     | | \___ \
# | |___  | |  ___) |
#  \____| |_| |____/
#
# ==============================================================================

# Run TritonCTS
# ------------------------------------------------------------------------------
# $(RESULTS_DIR)/4_1_cts.def: $(RESULTS_DIR)/3_place.def $(RESULTS_DIR)/3_place.sdc
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/cts.tcl -metrics $::env(LOG_DIR)/4_1_cts.json |& tee >&@stdout $::env(LOG_DIR)/4_1_cts.log

# Filler cell insertion
# ------------------------------------------------------------------------------
# $(RESULTS_DIR)/4_2_cts_fillcell.def: $(RESULTS_DIR)/4_1_cts.def
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/fillcell.tcl -metrics $::env(LOG_DIR)/4_2_cts_fillcell.json |& tee >&@stdout $::env(LOG_DIR)/4_2_cts_fillcell.log

# $(RESULTS_DIR)/4_cts.sdc: $(RESULTS_DIR)/4_cts.def

# $(RESULTS_DIR)/4_cts.def: $(RESULTS_DIR)/4_2_cts_fillcell.def
exec cp $::env(RESULTS_DIR)/4_2_cts_fillcell.def $::env(RESULTS_DIR)/4_cts.def

exec xvfb-run -a klayout -z \
    -rd input_layout=$::env(RESULTS_DIR)/4_cts.def \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rd tech_layer=$::env(KLAYOUT_TECH_LAYER_FILE) \
    -rm $::env(UTILS_DIR)/scsKlayout.py \
    |& tee >&@stdout $::env(LOG_DIR)/4_klayout_def.log

# clean_cts:
# 	rm -rf $(RESULTS_DIR)/4_*cts*.def $(RESULTS_DIR)/4_cts.sdc
# 	rm -f  $(REPORTS_DIR)/4_*
# 	rm -f  $(LOG_DIR)/4_*


# ==============================================================================
#  ____   ___  _   _ _____ ___ _   _  ____
# |  _ \ / _ \| | | |_   _|_ _| \ | |/ ___|
# | |_) | | | | | | | | |  | ||  \| | |  _
# |  _ <| |_| | |_| | | |  | || |\  | |_| |
# |_| \_\\___/ \___/  |_| |___|_| \_|\____|
#
# ==============================================================================


# STEP 1: Run global route
#-------------------------------------------------------------------------------
# $(RESULTS_DIR)/route.guide: $(RESULTS_DIR)/4_cts.def
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/global_route.tcl -metrics $::env(LOG_DIR)/5_1_fastroute.json |& tee >&@stdout $::env(LOG_DIR)/5_1_fastroute.log


# STEP 2: Run detail route
#-------------------------------------------------------------------------------

# Generate param file for TritonRoute
#-------------------------------------------------------------------------------
# ifneq ($(GENERIC_TECH_LEF),)
#   export TRITON_ROUTE_LEF := $(OBJECTS_DIR)/generic_merged_spacing.lef
# else
#   export TRITON_ROUTE_LEF := $(OBJECTS_DIR)/merged_spacing.lef
# endif

set ::env(TRITON_ROUTE_LEF) $::env(OBJECTS_DIR)/merged_spacing.lef

lappend TritonRoute_param "lef:$::env(TRITON_ROUTE_LEF)"
lappend TritonRoute_param "def:$::env(RESULTS_DIR)/4_cts.def"
lappend TritonRoute_param "guide:$::env(RESULTS_DIR)/route.guide"
lappend TritonRoute_param "output:$::env(RESULTS_DIR)/5_route.def" 
lappend TritonRoute_param "outputTA:$::env(OBJECTS_DIR)/5_route_TA.def" 
lappend TritonRoute_param "outputguide:$::env(RESULTS_DIR)/output_guide.mod" 
lappend TritonRoute_param "outputDRC:$::env(REPORTS_DIR)/5_route_drc.rpt" 
lappend TritonRoute_param "outputMaze:$::env(RESULTS_DIR)/maze.log" 
lappend TritonRoute_param "threads:$::env(NUM_CORES)" 
lappend TritonRoute_param "cpxthreads:1" 
lappend TritonRoute_param "verbose:1" 
lappend TritonRoute_param "gap:0" 
lappend TritonRoute_param "timeout:2400" 

set fp [open "$::env(OBJECTS_DIR)/TritonRoute.param" w+]
puts $fp [join $TritonRoute_param \n]
close $fp

# Run TritonRoute
#-------------------------------------------------------------------------------
# ifeq ($(USE_WXL),)
# $(RESULTS_DIR)/5_route.def: $(RESULTS_DIR)/route.guide
# endif
# $(RESULTS_DIR)/5_route.def: $::env((OBJECTS_DIR)/TritonRoute.param $::env((RESULTS_DIR)/4_cts.def
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/detail_route.tcl -metrics $::env(LOG_DIR)/5_2_TritonRoute.json |& tee >&@stdout $::env(LOG_DIR)/5_2_TritonRoute.log

exec xvfb-run -a klayout -z \
    -rd input_layout=$::env(RESULTS_DIR)/5_route.def \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rd tech_layer=$::env(KLAYOUT_TECH_LAYER_FILE) \
    -rm $::env(UTILS_DIR)/scsKlayout.py \
    |& tee >&@stdout $::env(LOG_DIR)/5_klayout_def.log

# $(RESULTS_DIR)/5_route.sdc: $(RESULTS_DIR)/4_cts.sdc
exec cp $::env(RESULTS_DIR)/4_cts.sdc $::env(RESULTS_DIR)/5_route.sdc

# clean_route:
# 	rm -rf output*/ results*.out.dmp layer_*.mps
# 	rm -rf *.gdid *.log *.met *.sav *.res.dmp
# 	rm -rf $(RESULTS_DIR)/route.guide $(OBJECTS_DIR)/TritonRoute.param
# 	rm -rf $(RESULTS_DIR)/5_route.def $(RESULTS_DIR)/5_route.sdc $(OBJECTS_DIR)/5_route_TA.def
# 	rm -f  $(REPORTS_DIR)/5_*
# 	rm -f  $(LOG_DIR)/5_*

# # klayout_tr_rpt: $(RESULTS_DIR)/5_route.def $(OBJECTS_DIR)/klayout.lyt
# exec xvfb-run -a klayout -rd in_drc=$::env(REPORTS_DIR)/5_route_drc.rpt \
#         -rd in_def=$::env(RESULTS_DIR)/5_route.def \
#         -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
#         -rm $::env(UTILS_DIR)/viewDrc.py

# # klayout_guides: $(RESULTS_DIR)/5_route.def
# exec xvfb-run -a klayout -rd in_guide=$::env(RESULTS_DIR)/route.guide \
#         -rd in_def=$::env(RESULTS_DIR)/5_route.def \
#         -rd net_name=$::env(GUIDE_NET) \
#         -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
#         -rm $::env(UTILS_DIR)/viewGuide.py


# ==============================================================================
#  _____ ___ _   _ ___ ____  _   _ ___ _   _  ____
# |  ___|_ _| \ | |_ _/ ___|| | | |_ _| \ | |/ ___|
# | |_   | ||  \| || |\___ \| |_| || ||  \| | |  _
# |  _|  | || |\  || | ___) |  _  || || |\  | |_| |
# |_|   |___|_| \_|___|____/|_| |_|___|_| \_|\____|
#
# ==============================================================================

# ifneq ($(USE_FILL),)
# $(RESULTS_DIR)/6_1_fill.def: $(RESULTS_DIR)/5_route.def
# 	($(TIME_CMD) $(OPENROAD_CMD) $(SCRIPTS_DIR)/density_fill.tcl -metrics $(LOG_DIR)/6_density_fill.json) 2>&1 | tee $(LOG_DIR)/6_density_fill.log
# else
# $(RESULTS_DIR)/6_1_fill.def: $(RESULTS_DIR)/5_route.def
# 	cp $< $@
# endif

# $(RESULTS_DIR)/6_1_fill.def: $(RESULTS_DIR)/5_route.def
exec cp $::env(RESULTS_DIR)/5_route.def $::env(RESULTS_DIR)/6_1_fill.def

# $(RESULTS_DIR)/6_1_fill.sdc: $(RESULTS_DIR)/5_route.sdc
exec cp $::env(RESULTS_DIR)/5_route.sdc $::env(RESULTS_DIR)/6_1_fill.sdc

# $(REPORTS_DIR)/6_final_report.rpt: $(RESULTS_DIR)/6_1_fill.def $(RESULTS_DIR)/6_1_fill.sdc
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/final_report.tcl -metrics $::env(LOG_DIR)/6_report.json |& tee >&@stdout $::env(LOG_DIR)/6_report.log

exec xvfb-run -a klayout -z \
    -rd input_layout=$::env(RESULTS_DIR)/6_final.def \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rd tech_layer=$::env(KLAYOUT_TECH_LAYER_FILE) \
    -rm $::env(UTILS_DIR)/scsKlayout.py \
    |& tee >&@stdout $::env(LOG_DIR)/6_klayout_def.log

# $(RESULTS_DIR)/6_final.def: $(REPORTS_DIR)/6_final_report.rpt

# Merge wrapped macros using Klayout
#-------------------------------------------------------------------------------
# $(WRAPPED_GDS): $(OBJECTS_DIR)/klayout_wrap.lyt $(WRAPPED_LEFS)
# 	($(TIME_CMD) klayout -zz -rd design_name=$(basename $(notdir $@)) \
# 	        -rd in_def=$(OBJECTS_DIR)/def/$(notdir $(@:gds=def)) \
# 	        -rd in_gds="$(ADDITIONAL_GDS)" \
# 	        -rd config_file=$(FILL_CONFIG) \
# 	        -rd seal_gds="" \
# 	        -rd out_gds=$@ \
# 	        -rd tech_file=$(OBJECTS_DIR)/klayout_wrap.lyt \
# 	        -rm $(UTILS_DIR)/def2gds.py) 2>&1 | tee $(LOG_DIR)/6_merge_$(basename $(notdir $@)).log

# Merge GDS using Klayout
#-------------------------------------------------------------------------------
# $(RESULTS_DIR)/6_1_merged.gds: $(OBJECTS_DIR)/klayout.lyt $(GDS_FILES) $(WRAPPED_GDS) $(RESULTS_DIR)/6_final.def

####temp variables
set ::env(WRAPPED_GDS) {}
set SEAL_GDS {}
####temp variables
exec stdbuf -o L klayout -zz -rd design_name=$::env(DESIGN_NAME) \
    -rd in_def=$::env(RESULTS_DIR)/6_final.def \
    -rd in_gds=$::env(GDS_FILES) $::env(WRAPPED_GDS) \
    -rd config_file=$::env(FILL_CONFIG) \
    -rd seal_gds=$SEAL_GDS \
    -rd out_gds=$::env(RESULTS_DIR)/6_1_merged.gds \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rm $::env(UTILS_DIR)/def2gds.py |& tee >&@stdout $::env(LOG_DIR)/6_1_merge.log

# $(RESULTS_DIR)/6_final.v: $(REPORTS_DIR)/6_final_report.rpt

# $(RESULTS_DIR)/6_final.gds: $(RESULTS_DIR)/6_1_merged.gds
exec cp $::env(RESULTS_DIR)/6_1_merged.gds $::env(RESULTS_DIR)/6_final.gds

exec xvfb-run -a klayout -z \
    -rd input_layout=$::env(RESULTS_DIR)/6_final.gds \
    -rd tech_file=$::env(OBJECTS_DIR)/klayout.lyt \
    -rd tech_layer=$::env(KLAYOUT_TECH_LAYER_FILE) \
    -rm $::env(UTILS_DIR)/scsKlayout.py \
    |& tee >&@stdout $::env(LOG_DIR)/6_klayout_gds.log

exec klayout -b \
    -rd input=$::env(RESULTS_DIR)/6_final.gds \
    -rd report=$::env(REPORTS_DIR)/6_drc_count.rpt \
    -r $::env(KLAYOUT_TECH_DRC_FILE) \
    |& tee >&@stdout $::env(LOG_DIR)/6_drc.log

# drc: $(REPORTS_DIR)/6_drc.lyrdb

# $(REPORTS_DIR)/6_drc.lyrdb: $(RESULTS_DIR)/6_final.gds $(KLAYOUT_DRC_FILE)
# ifneq ($(KLAYOUT_DRC_FILE),)
# 	($(TIME_CMD) klayout -zz -rd in_gds="$<" \
# 	        -rd report_file=$(abspath $@) \
# 	        -r $(KLAYOUT_DRC_FILE)) 2>&1 | tee $(LOG_DIR)/6_drc.log
# 	# Hacky way of getting DRV count (don't error on no matches)
# 	grep -c "<value>" $@ > $(REPORTS_DIR)/6_drc_count.rpt || [[ $$? == 1 ]]
# else
# 	echo "DRC not supported on this platform" > $@
# endif

# $(RESULTS_DIR)/6_final.cdl: $(RESULTS_DIR)/6_final.v
exec openroad -no_init -exit $::env(SCRIPTS_DIR)/cdl.tcl |& tee >&@stdout $::env(LOG_DIR)/6_cdl.log

# $(OBJECTS_DIR)/6_final_concat.cdl: $(RESULTS_DIR)/6_final.cdl $(CDL_FILE)
# exec cat $::env(RESULTS_DIR)/6_final.cdl > $::env(OBJECTS_DIR)/6_final_concat.cdl

lappend cdl_list $::env(RESULTS_DIR)/6_final.cdl
# lappend cdl_list $::env(CDL_FILE)
set cdl_out [open $::env(OBJECTS_DIR)/6_final.sp w+]
puts $cdl_out ".GLOBAL VDD VSS"
foreach file $cdl_list {
    set f [open [file normalize $file] r]
    fcopy $f $cdl_out
    close $f
} 
close $cdl_out 


# lvs: $(RESULTS_DIR)/6_lvs.lvsdb

# $(RESULTS_DIR)/6_lvs.lvsdb: $(RESULTS_DIR)/6_final.gds $(KLAYOUT_LVS_FILE) $(OBJECTS_DIR)/6_final_concat.cdl
# ifneq ($(KLAYOUT_LVS_FILE),)
# 	($(TIME_CMD) klayout -b -rd in_gds="$<" \
# 	        -rd cdl_file=$(abspath $(OBJECTS_DIR)/6_final_concat.cdl) \
# 	        -rd report_file=$(abspath $@) \
# 	        -r $(KLAYOUT_LVS_FILE)) 2>&1 | tee $(LOG_DIR)/6_lvs.log
# else
# 	echo "LVS not supported on this platform" > $@
# endif

# LVS
exec klayout -b -rd input=$::env(RESULTS_DIR)/6_final.gds \
    -rd schematic=$::env(OBJECTS_DIR)/6_final.sp \
    -rd report=$::env(RESULTS_DIR)/6_lvs1.lvsdb \
    -rd target_netlist=$::env(OBJECTS_DIR)/6_ext.cir \
    -r $::env(KLAYOUT_LVS_FILE) \
    |& tee >&@stdout $::env(LOG_DIR)/6_lvs1.log

set LVS_CONF [open $::env(OBJECTS_DIR)/net_gen.lvs w+]
set SP_FILES [regexp -all -inline {\S+} $::env(SP_FILE)]
foreach file $SP_FILES {
    puts $LVS_CONF "readnet spice $file \n"
} 
puts $LVS_CONF "lvs \{$::env(OBJECTS_DIR)/6_ext.cir $::env(DESIGN_NAME)\} \
    \{$::env(OBJECTS_DIR)/6_final.sp $::env(DESIGN_NAME)\} \
    $::env(NETGEN_LVS)/sky130_setup.tcl $::env(REPORTS_DIR)/6_lvs2.rpt\n"
close $LVS_CONF

exec netgen -batch source $::env(OBJECTS_DIR)/net_gen.lvs \
    |& tee >&@stdout $::env(LOG_DIR)/6_lvs2.log

# clean_finish:
# 	rm -rf $(RESULTS_DIR)/6_*.gds $(RESULTS_DIR)/6_*.def $(RESULTS_DIR)/6_*.v
# 	rm -rf $(REPORTS_DIR)/6_*.rpt
# 	rm -f  $(LOG_DIR)/6_*





