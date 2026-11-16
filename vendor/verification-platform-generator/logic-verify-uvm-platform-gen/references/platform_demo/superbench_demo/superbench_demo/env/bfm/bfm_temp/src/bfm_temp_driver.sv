//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:15
//Abstract        : bfm_temp_driver
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 16:09:15, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _bfm_temp_driver_CLASS_
`define _bfm_temp_driver_CLASS_

class bfm_temp_driver  #(      // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE = uvm_sequence_item, // GAEA_PLATFORM::PARAMETER
    int  DAT_WIDTH = 32                 // GAEA_PLATFORM::PARAMETER
    )extends uvm_driver ;                // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_peek_port  inport;  // GAEA_PLATFORM::INPORT 
    //!GAEA_BLOCK_END_CHANNELDECL                                                

    int     chn_num ;
    bfm_temp_cfg                                          cfg;       // NOTICE:configure instance is cfg
    virtual bfm_temp_driver_intf #(.DAT_WIDTH(DAT_WIDTH)) drv_bus;   // NOTICE:interface instance is bus
    glb_dec::if_vip_work_mode      work_mode = glb_dec::NORMAL;                   // NOTICE:work_mode type should be NORMAL,NORMAL_WITH_MONITOR,DRIVER,DRIVER_WITH_MONITOR,MONITOR 

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual task run_phase(uvm_phase phase);

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here
    extern   task    driver() ;
    // END: EDITABLE SECTION

    `uvm_component_param_utils(bfm_temp_driver #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH)))
endclass:bfm_temp_driver

function bfm_temp_driver::new (string name, uvm_component parent);
    super.new(name, parent);
    chn_num = 1;

    //!GAEA_BLOCK_BEGIN_CHANNELINST
    inport = new("inport",this); 
    //!GAEA_BLOCK_END_CHANNELINST

    // BEGIN: EDITABLE SECTION

    // END: EDITABLE SECTION
endfunction:new

function void bfm_temp_driver::build_phase(uvm_phase phase) ;
    super.build_phase(phase);


    // BEGIN: EDITABLE SECTION
    work_mode = cfg.work_mode;
    // END: EDITABLE SECTION

endfunction

task bfm_temp_driver::run_phase(uvm_phase phase) ;
    super.run_phase(phase);

    // BEGIN: EDITABLE SECTION
    // Write your codes here
    driver();
    // END: EDITABLE SECTION
endtask:run_phase

task bfm_temp_driver::driver() ;
    //DATA_TYPE               	pkt_in;
    //uvm_sequence_item       	trans;
    //bit [7:0]             	drv_data[];
    //int			tx_ex_dat_tmp;
    //bit			pkt_err_tmp;
    //int			i_len;
    //int			i_mod;
    //bit [DAT_WIDTH-1:0]    	b_temp;

    //if (TX_EN == 0) return ;

    //forever begin
    //    @(posedge drv_bus.clk);
    //    this.drv_bus.fifo_val <= 'b0;
    //    this.drv_bus.fifo_sop <= 'b0;
    //    this.drv_bus.fifo_eop <= 'b0;
    //    this.drv_bus.fifo_mod <= 'b0;
    //    this.drv_bus.fifo_err <= 'b0;
    //    this.drv_bus.fifo_dat <= 'b0;
    //    this.drv_bus.fifo_ex_dat <= 'b0;

    //    inport.get(trans);
    //    //`uvm_info(get_type_name(),$psprintf("debug:get a pkt from Gen \n %0s",trans.sprint()),UVM_MEDIUM);
    //    if(!$cast(pkt_in,trans.clone()))
    //        `uvm_fatal(get_type_name(),"the data cast is failed,please check");
    //    `uvm_info(get_type_name(),$psprintf("debug:get a pkt from Gen after clone() \n %0s",pkt_in.sprint()),UVM_MEDIUM);
    //    wait(drv_bus.fifo_rdy == 1);

    //    pkt_in.pack_bytes(drv_data);
    //    //`uvm_info(get_type_name(),$psprintf("debug:drv_data size is %d \n",drv_data.size()),UVM_MEDIUM);

    //    if(0 == drv_data.size()) begin
    //        `uvm_error(get_type_name(), "the packet's length is zero!");
    //    end
    //    //the BUS width is 64bits
    //    i_mod = drv_data.size()%(DAT_WIDTH/8);

    //    if(0 == i_mod)
    //        i_len = drv_data.size()/(DAT_WIDTH/8);
    //    else
    //        i_len = int'(drv_data.size()/(DAT_WIDTH/8))+1;

    //    for(int i = 0; i < i_len; i++) begin
    //        @(posedge this.drv_bus.clk);
    //        this.drv_bus.fifo_val <=  1'b1;
    //        if((0 == i) && (1 == i_len)) begin
    //            this.drv_bus.fifo_sop <= 1'b1;
    //            this.drv_bus.fifo_eop <= 1'b1;
    //            this.drv_bus.fifo_mod <= i_mod;
    //            //this.drv_bus.fifo_err <= pkt_err_tmp;
    //        end
    //        else if((0 == i) && (1 != i_len)) begin
    //            this.drv_bus.fifo_sop <= 'b1;
    //            this.drv_bus.fifo_eop <= 'b0;
    //            this.drv_bus.fifo_mod <= 'b0;
    //            this.drv_bus.fifo_err <= 'b0;
    //        end
    //        else if((i_len-1) == i) begin
    //            this.drv_bus.fifo_sop <= 1'b0;
    //            this.drv_bus.fifo_eop <= 1'b1;
    //            this.drv_bus.fifo_mod <= i_mod;
    //            //this.drv_bus.fifo_err <= pkt_err_tmp;
    //        end
    //        else begin
    //            this.drv_bus.fifo_sop <= 'b0;
    //            this.drv_bus.fifo_eop <= 'b0;
    //            this.drv_bus.fifo_mod <= 'b0;
    //            this.drv_bus.fifo_err <= 'b0;
    //        end

    //        //`uvm_info(get_type_name(),$psprintf("debug:drv_data size is %d :i-%d :DAT_WIDTH:%d \n",drv_data.size(),i,DAT_WIDTH),UVM_MEDIUM);
    //        for(int j = 0; j < (DAT_WIDTH/8); j++) begin
    //            if((i_len-1) == i&&j>=i_mod) begin
    //                b_temp[((DAT_WIDTH-1)-j*8)-:8] = 'h0;
    //            end
    //            else begin
    //                b_temp[((DAT_WIDTH-1)-j*8)-:8] = drv_data[(DAT_WIDTH/8)*i+j];
    //            end
    //        end
    //        this.drv_bus.fifo_dat <= b_temp;
    //        //this.drv_bus.fifo_ex_dat <= pkt_in.chn_id;
    //    end
    //end
endtask:driver

`endif
