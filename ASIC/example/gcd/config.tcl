#!/usr/bin/tclsh
set ::env(DESIGN_NICKNAME) "gcd"
set ::env(DESIGN_NAME) "gcd"
set ::env(PDK_DIR) "/home/ychen/test/OSME/pdk/sky130hd"
set ::env(VERILOG_FILES) [glob $::env(PROJ_HOME_DIR)/v_src/*.v]
set ::env(SDC_FILE) "$::env(PROJ_HOME_DIR)/constraint.sdc"

# Set Directories
set ::env(LOG_DIR) "$::env(PROJ_HOME_DIR)/logs"
set ::env(OBJECTS_DIR) "$::env(PROJ_HOME_DIR)/objects"
set ::env(REPORTS_DIR) "$::env(PROJ_HOME_DIR)/reports"
set ::env(RESULTS_DIR) "$::env(PROJ_HOME_DIR)/results"

set ::env(SCRIPTS_DIR) "/home/ychen/test/OSME/ASIC/scripts"
set ::env(UTILS_DIR) "/home/ychen/test/OSME/ASIC/util"
# set ::env(TEST_DIR) "/home/ychen/openeda/OpenROAD-flow-scripts/flow/test"

# # Tool Options
# WRAPPED_LEFS = $(foreach lef,$(notdir $(WRAP_LEFS)),$(OBJECTS_DIR)/lef/$(lef:.lef=_mod.lef))
# WRAPPED_LIBS = $(foreach lib,$(notdir $(WRAP_LIBS)),$(OBJECTS_DIR)/$(lib:.lib=_mod.lib))
# export WRAPPED_GDS = $(foreach lef,$(notdir $(WRAP_LEFS)),$(OBJECTS_DIR)/$(lef:.lef=_mod.gds))
# export ADDITIONAL_LEFS += $(WRAPPED_LEFS) $(WRAP_LEFS)
# export LIB_FILES += $(WRAP_LIBS) $(WRAPPED_LIBS)



