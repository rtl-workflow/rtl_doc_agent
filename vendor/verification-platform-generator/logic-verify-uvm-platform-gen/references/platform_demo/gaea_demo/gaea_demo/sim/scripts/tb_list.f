// basic
../../env/common/base_report_server.sv
../../env/common/glb_dec.sv
../../env/common/sqr_to_func.sv
../../env/funcov/basic_fcov.sv
///eda/GaeaPlatform/comm_lib/ucli/tcl_cmd_program.sv
//-F /data/logic_assets/LVP/LVP3.0/lvp_basic.list
../LVP/method/lvpm_dec.sv
../LVP/method/clk_module/god_clk.sv
../LVP/method/clk_module/tb_clk_gen.sv
../LVP/method/common/public_define_func.sv
../LVP/lvp_dut_cfg_base.sv

// ral basic
../../env/ral/cpu_transaction.sv
../../env/ral/cpu_adapter.sv
../../env/ral/cpu_sqr.sv

// component
//!GAEA_BLOCK_BEGIN_FILELIST
../../env/gen/gen_temp/src/gen_temp_cfg.sv
../../env/gen/gen_temp/src/gen_temp_sequence.sv
../../env/gen/gen_temp/src/gen_temp_sqr_to_func.sv
../../env/gen/gen_temp/src/gen_temp.sv


../../env/rm/func_single_scoreboard/src/func_single_scoreboard_cfg.sv
../../env/rm/func_single_scoreboard/src/func_single_scoreboard.sv


../../env/bfm/bfm_temp/src/bfm_temp_cfg.sv
../../env/bfm/bfm_temp/src/bfm_temp_intf.sv
../../env/bfm/bfm_temp/src/bfm_temp_receiver.sv
../../env/bfm/bfm_temp/src/bfm_temp_monitor.sv
../../env/bfm/bfm_temp/src/bfm_temp_driver.sv
../../env/bfm/bfm_temp/src/bfm_temp.sv


../../env/rm/rm_temp/src/rm_temp_cfg.sv
../../env/rm/rm_temp/src/rm_temp.sv


../../env/bfm/bfm_cbus/src/bfm_cbus_cfg.sv
../../env/bfm/bfm_cbus/src/bfm_cbus_intf.sv
../../env/bfm/bfm_cbus/src/bfm_cbus.sv


//!GAEA_BLOCK_END_FILELIST

// ral
../../env/ral/top_cib_model.sv

// subenv
//!GAEA_BLOCK_BEGIN_SUBENV_FILELIST

//!GAEA_BLOCK_END_SUBENV_FILELIST

// env
../../env/gaea_demo_dut_cfg.sv
../../env/gaea_demo_env_cfg.sv
../../env/gaea_demo_env.sv

//../../tests/basic_tc.sv
-F ../../sim/scripts/tc_list.f
-F ../../tests/tc.list
