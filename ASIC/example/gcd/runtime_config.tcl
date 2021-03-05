#!/usr/bin/tclsh

# These values must be multiples of placement site
set ::env(DIE_AREA) "0 0 279.96 280.128"
set ::env(CORE_AREA) "19.996 10.08 269.964 270.048"
set ::env(ABC_CLOCK_PERIOD_IN_PS) "10"

#### YOSYS
# Used in synthesis
set ::env(MIN_BUF_CELL_AND_PORTS) "sky130_fd_sc_hd__buf_4 A X"

# Used in synthesis
set ::env(MAX_FANOUT) "5"
#### YOSYS

#### Placement
set ::env(MACRO_PLACE_HALO) "1 1"
set ::env(MACRO_PLACE_CHANNEL) "80 80"

set ::env(PLACE_DENSITY) "0.60"
#### Placement

#### TritonCTS
set ::env(CTS_BUF_CELL) "sky130_fd_sc_hd__buf_1"
set ::env(CTS_MAX_SLEW) "1.5e-9"
set ::env(CTS_MAX_CAP) ".1532e-12"
#### TritonCTS

#### FastRoute
set ::env(MIN_ROUTING_LAYER) "2"
set ::env(MAX_ROUTING_LAYER) "6"
#### FastRoute

#### Routing
# Cell padding in SITE widths to ease rout-ability
set ::env(CELL_PAD_IN_SITES) "4"

