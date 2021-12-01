create_project ov7670 ov7670
set_property board_part em.avnet.com:minized:part0:1.2 [current_project]

add_files .
create_bd_design "platform"

open_bd_design ov7670/ov7670.srcs/sources_1/bd/platform/platform.bd
create_bd_cell -type module -reference ov7670_axi_stream_capture ov7670_axi_stream_ca_0
create_bd_cell -type module -reference ov7670_controller ov7670_controller_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
set_property -dict [list CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER] [get_bd_cells axi_vdma_0]
set_property -dict [list CONFIG.c_m_axi_s2mm_data_width {32} CONFIG.c_num_fstores {1} CONFIG.c_mm2s_genlock_mode {0} CONFIG.c_include_mm2s {0}] [get_bd_cells axi_vdma_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_EN_CLK1_PORT {0} CONFIG.PCW_IRQ_F2P_INTR {1}] [get_bd_cells processing_system7_0]

set_property location {2.5 1342 331} [get_bd_cells axi_vdma_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_vdma_0/S_AXI_LITE} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]

connect_bd_intf_net [get_bd_intf_pins ov7670_axi_stream_ca_0/m_axis] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins smartconnect_0/S00_AXI]

#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Clk_slave {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Clk_xbar {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Master {/axi_vdma_0/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/smartconnect_0} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]





connect_bd_net [get_bd_pins smartconnect_0/aclk] [get_bd_pins ov7670_axi_stream_ca_0/aclk]
connect_bd_net [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk]
connect_bd_net [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins ov7670_axi_stream_ca_0/aclk]
connect_bd_net [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins ov7670_axi_stream_ca_0/aclk]


apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (49 MHz)" }  [get_bd_pins ov7670_controller_0/clk]
connect_bd_net [get_bd_pins smartconnect_0/aresetn] [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_vdma_0/s2mm_introut] [get_bd_pins processing_system7_0/IRQ_F2P]

#CRIA BRAM DE CONFIG 
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
#CONFIGURA PARA TRUEDUALPORT
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]



#CRIA AXIBRAMCONFIG
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
#CONFIGURA PARA UM ACESSO
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]


apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Clk_slave {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Clk_xbar {/ov7670_axi_stream_ca_0/aclk (100 MHz)} Master {/axi_vdma_0/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/smartconnect_0} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]

apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (50 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (50 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_bram_ctrl_0/S_AXI} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

## FIX ME: nao sei pq precisamos de mais um aqui.
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]

create_bd_cell -type module -reference trintatodeze trintatodeze_0

#connect_bd_net [get_bd_pins blk_mem_gen_0/dout] [get_bd_pins trintatodeze_0/A]
#connect_bd_net [get_bd_pins trintatodeze_0/B] [get_bd_pins ov7670_controller_0/command_reg]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
#connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins blk_mem_gen_0/enb]

connect_bd_net [get_bd_pins trintatodeze_0/B] [get_bd_pins ov7670_controller_0/command_reg]
connect_bd_net [get_bd_pins trintatodeze_0/A] [get_bd_pins blk_mem_gen_0/doutb]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins blk_mem_gen_0/enb]
connect_bd_net [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins processing_system7_0/FCLK_CLK0]

create_bd_cell -type module -reference comandostop_v1_0 comandostop_v1_0_0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (50 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (50 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/comandostop_v1_0_0/s00_axi} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins comandostop_v1_0_0/s00_axi]
connect_bd_net [get_bd_pins comandostop_v1_0_0/conf_end] [get_bd_pins ov7670_controller_0/config_finished]
connect_bd_net [get_bd_pins comandostop_v1_0_0/vsync_i] [get_bd_pins ov7670_axi_stream_ca_0/vsync]


create_bd_cell -type module -reference debounce debounce_0
connect_bd_net [get_bd_pins debounce_0/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins comandostop_v1_0_0/debounce] [get_bd_pins debounce_0/i]
connect_bd_net [get_bd_pins debounce_0/o] [get_bd_pins ov7670_controller_0/resend]
connect_bd_net [get_bd_pins ov7670_controller_0/address_bram] [get_bd_pins blk_mem_gen_0/addrb]


#Criando as portas do VGA
create_bd_port -dir I -from 7 -to 0 d_0
create_bd_port -dir I href
create_bd_port -dir I vsync
create_bd_port -dir I pclk
#Conectando as portas do VGA
connect_bd_net [get_bd_ports d_0] [get_bd_pins ov7670_axi_stream_ca_0/d]
connect_bd_net [get_bd_ports pclk] [get_bd_pins ov7670_axi_stream_ca_0/pclk]
connect_bd_net [get_bd_ports href] [get_bd_pins ov7670_axi_stream_ca_0/href]
connect_bd_net [get_bd_ports vsync] [get_bd_pins ov7670_axi_stream_ca_0/vsync]


#Criando as portas do I2C
create_bd_port -dir O pwdn
create_bd_port -dir IO siod
create_bd_port -dir O sioc
create_bd_port -dir O reset
create_bd_port -dir O xclk
#Conectando as portas do I2C
connect_bd_net [get_bd_ports xclk] [get_bd_pins ov7670_controller_0/xclk]
connect_bd_net [get_bd_ports reset] [get_bd_pins ov7670_controller_0/reset]
connect_bd_net [get_bd_ports sioc] [get_bd_pins ov7670_controller_0/sioc]
connect_bd_net [get_bd_ports siod] [get_bd_pins ov7670_controller_0/siod]
connect_bd_net [get_bd_ports pwdn] [get_bd_pins ov7670_controller_0/pwdn]

save_bd_design


make_wrapper -files [get_files ./ov7670/ov7670.srcs/sources_1/bd/platform/platform.bd] -top
add_files -norecurse ./ov7670/ov7670.srcs/sources_1/bd/platform/hdl/platform_wrapper.v

set_property top platform_wrapper [current_fileset]

add_files -fileset constrs_1 -norecurse ./camera/mzed.xdc


launch_runs impl_1 -to_step write_bitstream -jobs [exec "nproc"]
wait_on_run impl_1 

start_gui

