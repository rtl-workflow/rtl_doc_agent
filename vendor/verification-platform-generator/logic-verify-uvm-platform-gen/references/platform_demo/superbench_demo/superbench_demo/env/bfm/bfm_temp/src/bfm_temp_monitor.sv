//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:15
//Abstract        : bfm_temp_monitor
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

`ifndef _bfm_temp_monitor_CLASS_
`define _bfm_temp_monitor_CLASS_

class bfm_temp_monitor  #(       // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE = uvm_sequence_item, // GAEA_PLATFORM::PARAMETER
    int  DAT_WIDTH = 32                 // GAEA_PLATFORM::PARAMETER
    )extends uvm_component ;                  // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_put_port  outport;  // GAEA_PLATFORM::OUTPORT 
    //!GAEA_BLOCK_END_CHANNELDECL                                                

    bfm_temp_cfg                                           cfg;       // NOTICE:configure instance is cfg
    virtual bfm_temp_monitor_intf #(.DAT_WIDTH(DAT_WIDTH)) mon_bus;   // NOTICE:interface instance is bus
    glb_dec::if_vip_work_mode      work_mode = glb_dec::NORMAL;                    // NOTICE:work_mode type should be NORMAL,NORMAL_WITH_MONITOR,DRIVER,DRIVER_WITH_MONITOR,MONITOR 

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual task run_phase(uvm_phase phase);

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here
    extern   task    monitor() ;
    // END: EDITABLE SECTION

    `uvm_component_param_utils(bfm_temp_monitor #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH)))
endclass:bfm_temp_monitor

function bfm_temp_monitor::new (string name, uvm_component parent);
    super.new(name, parent);

    //!GAEA_BLOCK_BEGIN_CHANNELINST
    outport = new("outport",this); 
    //!GAEA_BLOCK_END_CHANNELINST


endfunction:new

function void bfm_temp_monitor::build_phase(uvm_phase phase) ;
    work_mode = cfg.work_mode;

    // BEGIN: EDITABLE SECTION
    // END: EDITABLE SECTION

endfunction

task bfm_temp_monitor::run_phase(uvm_phase phase) ;
    super.run_phase(phase);

    // BEGIN: EDITABLE SECTION
    // Write your codes here
    monitor();
    // END: EDITABLE SECTION
endtask:run_phase

task bfm_temp_monitor::monitor() ;
    //bit     [7:0]          data_tmp[$]      ;
    //byte unsigned          rcv_data[]       ;
    //int                    rcv_data_size    ;
    //int                    i_sop_flag       ;
    //int                    i_flag           ;
    //int                    i                ;
    //bit                    iErrFlag         ;
    //bit[EX_DAT_WIDTH-1:0]  ex_dat           ;
    //DATA_TYPE              pkt_out          ;

    //forever begin
    //   i_sop_flag = 0;
    //   i_flag = 1;

    //   while(i_flag) begin
    //       @(posedge this.rcv_bus.clk);
    //       if(this.rcv_bus.fifo_val == 1'b1) begin
    //           if((this.rcv_bus.fifo_sop == 1'b1) && (this.rcv_bus.fifo_eop == 1'b1))
    //           begin
    //               ex_dat = rcv_bus.fifo_ex_dat;
    //               data_tmp = {};
    //               if(1 == i_sop_flag) begin
    //                   `uvm_error(get_type_name(), "Receive a packet without eop!");
    //               end
    //               if(this.rcv_bus.fifo_err == 1'b1) begin
    //                   `uvm_error(get_type_name(), "Receive a error packet!");
    //                   iErrFlag = 1;
    //               end
    //               else begin
    //                   if(0 == this.rcv_bus.fifo_mod) begin
    //                       for(i = 0; i < (DAT_WIDTH/8); i++) begin
    //                           data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //                       end
    //                   end
    //                   else begin
    //                       for(i = 0; i < this.rcv_bus.fifo_mod; i++) begin
    //                           data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //                       end
    //                   end
    //                   iErrFlag = 1;
    //               end
    //               i_flag = 0;
    //           end
    //           else if(this.rcv_bus.fifo_sop == 1'b1) begin
    //               ex_dat = rcv_bus.fifo_ex_dat;
    //               data_tmp = {};
    //               if(1 == i_sop_flag) begin
    //                   `uvm_error(get_type_name(), "Receive a packet without eop!");
    //               end
    //               for(i = 0; i < (DAT_WIDTH/8); i++) begin
    //                   data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //               end
    //               i_sop_flag = 1;
    //           end
    //           else if(this.rcv_bus.fifo_eop == 1'b1) begin
    //               if(0 == i_sop_flag) begin
    //                   `uvm_error(get_type_name(), "Receive a packet without sop!");
    //                   iErrFlag = 1;
    //               end
    //               else if(this.rcv_bus.fifo_err == 1'b1) begin
    //                   `uvm_error(get_type_name(), "Receive a error packet!");
    //                   iErrFlag = 1;
    //               end
    //               else begin
    //                   if(0 == this.rcv_bus.fifo_mod) begin
    //                       for(i = 0; i < (DAT_WIDTH/8); i++) begin
    //                           data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //                       end
    //                   end
    //                   else begin
    //                       for(i = 0; i < this.rcv_bus.fifo_mod; i++) begin
    //                           data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //                       end
    //                   end
    //                   iErrFlag = 0;
    //               end
    //               i_flag = 0;
    //           end
    //           else begin
    //               for(i = 0; i < (DAT_WIDTH/8); i++) begin
    //                   data_tmp.push_back(this.rcv_bus.fifo_dat[((DAT_WIDTH-1)-i*8)-:8]);
    //               end
    //           end
    //       end
    //   end

    //   pkt_out = new;
    //   rcv_data_size = data_tmp.size();
    //   rcv_data = new[rcv_data_size];
    //   for (int i=0;i<rcv_data_size;i++)
    //   begin
    //        rcv_data[i]=data_tmp.pop_front(); 
    //   end
    //   //packer.use_metadata = 1'b1;
    //   //pkt_out.unpack_bytes(rcv_data,packer);
    //   pkt_out.unpack_bytes(rcv_data);
    //   //pkt_out.chn_id = ex_dat;
    //   //`uvm_info(get_type_name(),"debug:received a pkt from dut",UVM_MEDIUM);
    //   //pkt_out.sprint();
    //   `uvm_info(get_type_name(),$psprintf("debug:received a pkt from dut \n %0s",pkt_out.sprint()),UVM_MEDIUM);
    //   this.outport.put(pkt_out);
    //end
endtask:monitor

`endif
