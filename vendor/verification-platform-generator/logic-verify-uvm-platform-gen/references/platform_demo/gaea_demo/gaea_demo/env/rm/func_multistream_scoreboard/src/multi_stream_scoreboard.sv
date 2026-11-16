//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 17:08
//Abstract        :  multi_stream_scoreboard
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 17:08 ,)
//  ... version info ... 
//v1.0 new
//##################################################################
`ifndef MULTI_STREAM_SCOREBOARD_SV
`define MULTI_STREAM_SCOREBOARD_SV

class multi_stream_scoreboard#(type DATA_TYPE=uvm_sequence_item) // GAEA_PLATFORM::CLASSNAME
 extends uvm_component; // GAEA_PLATFORM::TYPE
    base_peek_port  exp_port; // GAEA_PLATFORM::INPORT
    base_peek_port  real_port; // GAEA_PLATFORM::INPORT

    multi_stream_scoreboard_cfg  cfg;

    DATA_TYPE expect_queue[$];
    DATA_TYPE actual_queue[$];
    DATA_TYPE exp_pkt,act_pkt,tmp_tran;
    DATA_TYPE trans_rcv_real,trans_exp_real;

    uvm_sequence_item trans_rcv_req,trans_exp_req;

    int unsigned n_matched    [*];
    int unsigned n_mismatched [*];
    int unsigned n_dropped    [*];
    int unsigned n_expect     [*];
    int unsigned n_actual     [*];
    int unsigned n_orphan     [*];

    int unsigned cyc_cnt = 0;

    extern function new(string name, uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern virtual task expect_in_order();
    extern virtual task expect_with_losses();
    extern virtual task expect_out_order();

    extern virtual function void flush();
    extern virtual function void scoreboard_report();
    extern virtual function void report_phase(uvm_phase phase);

    `uvm_component_utils(multi_stream_scoreboard#(.DATA_TYPE(DATA_TYPE)))
endclass

function multi_stream_scoreboard::new(string name, uvm_component parent = null);
    super.new(name,parent);
    this.exp_port = new($sformatf("exp_port"), this);
    this.real_port = new($sformatf("real_port"), this);
endfunction

function void multi_stream_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task multi_stream_scoreboard::main_phase(uvm_phase phase);
  super.main_phase(phase); 
  `uvm_info(get_type_name(),"main_phase is called",UVM_MEDIUM);
  fork
      forever
      begin
          exp_port.get(trans_exp_req);

          if(!$cast(trans_exp_real,trans_exp_req.clone()))
              `uvm_fatal(get_type_name(),"the data cast is failed,please check");

          if(cfg.scb_en==1) begin
             `uvm_info(get_type_name(),$psprintf("expect packet\n%0s",trans_exp_real.sprint()),UVM_HIGH)

             if(trans_exp_real.stream_id != cfg.ignore_id) begin 
                expect_queue.push_back(trans_exp_real);
                n_expect[trans_exp_real.stream_id] ++;
             end
             else begin
                `uvm_warning(get_type_name(),$psprintf("pkt of chan %d was ignored, the pkt is \n%s",cfg.ignore_id,trans_exp_real.sprint()))
             end
          end
      end

      forever
      begin
          real_port.get(trans_rcv_req);

          if(!$cast(trans_rcv_real,trans_rcv_req.clone()))
               `uvm_fatal(get_type_name(),"the data cast is failed,please check");

          if(cfg.scb_en==1) begin
             `uvm_info(get_type_name(),$psprintf("get packet\n%0s",trans_rcv_real.sprint()),UVM_MEDIUM)

             if(trans_rcv_real.stream_id != cfg.ignore_id) begin 
                actual_queue.push_back(trans_rcv_real);
                n_actual[trans_rcv_real.stream_id] ++;
             end
             else begin
                `uvm_warning(get_type_name(),$psprintf("pkt of chan %d was ignored, the pkt is \n%s",cfg.ignore_id,trans_rcv_real.sprint()))
             end
          end
      end

      begin
         if(cfg.comp_mode==glb_dec::IN_ORDER)
             expect_in_order();
         else if(cfg.comp_mode==glb_dec::WITH_LOSSES)
             expect_with_losses();
         else
             expect_out_order();
      end
  join_none
endtask

task multi_stream_scoreboard::expect_in_order();

    while(1) begin
        wait(actual_queue.size()>0);
        $cast(act_pkt, actual_queue[0]);

        //search by channel
        tmp_tran = null;
        for(int i=0;i<expect_queue.size() && expect_queue.size()>0;i++) begin
            $cast(exp_pkt, expect_queue[i].clone());

            if((act_pkt.stream_id != exp_pkt.stream_id)||exp_pkt == null) begin
               tmp_tran = null;
            end
            else begin
               $cast(tmp_tran , expect_queue[i].clone);

               expect_queue.delete(i--);

               if(act_pkt.compare(tmp_tran))begin 
                   n_matched[act_pkt.stream_id] ++;
                   `uvm_info(get_type_name(),"TRANS Matched in expect_in_order",UVM_LOW);
                   break;
               end
               else begin
                   n_mismatched[act_pkt.stream_id] ++;
                   `uvm_error(get_type_name(),$psprintf("expect pkt is \n%s while actual pkt is\n%s",exp_pkt.sprint(),act_pkt.sprint()));
                   break;
               end
            end
        end

        if(tmp_tran == null) begin
           if(cfg.latency_mode==glb_dec::LATENCY) begin
              if(cyc_cnt>cfg.delay_cyc) begin
                 `uvm_error(get_type_name(),$psprintf("logic output is earlier than testbench, actual pkt is\n%s",act_pkt.sprint()));
                 foreach(expect_queue[i]) begin
                     $cast(exp_pkt, expect_queue[i].clone());
                     `uvm_info(get_type_name(),$psprintf("RTL residue packet is \n%s", exp_pkt.sprint()), UVM_MEDIUM);
                 end
                 return;
              end
              else begin
                 cyc_cnt ++;
                 #1ns;
              end
           end
           else begin
              `uvm_error(get_type_name(),$psprintf("expect pkt not found, actual pkt is\n%s",act_pkt.sprint()));
              return;
           end
        end
        else begin
            cyc_cnt = 0;
            actual_queue.pop_front();
        end
    end
endtask


task multi_stream_scoreboard::expect_with_losses();

    while(1) begin
        wait(actual_queue.size()>0);
        $cast(act_pkt, actual_queue[0]);

        //search by channel
        tmp_tran = null;
        for(int i=0;i<expect_queue.size() && expect_queue.size()>0;i++) begin
            $cast(exp_pkt, expect_queue[i].clone());
            if((act_pkt.stream_id != exp_pkt.stream_id)||exp_pkt == null) begin
               tmp_tran = null;
            end
            else begin
               $cast(tmp_tran , expect_queue[i].clone);
               expect_queue.delete(i--);

               if(act_pkt.compare(tmp_tran))begin 
                   n_matched[act_pkt.stream_id] ++;
                   `uvm_info(get_type_name(),"TRANS Matched in expect_with_losses",UVM_LOW);
                   break;
               end
               else begin
                   n_dropped[act_pkt.stream_id] ++;

                   if(expect_queue.size()==0) begin
                      `uvm_error(get_type_name(),$psprintf("expect packet is not found,actual pkt is\n%s!", act_pkt.sprint()));
                      tmp_tran = null;
                   end
                   else begin
                      `uvm_info(get_type_name(),$psprintf("the lossed TRANS is\n%0s",tmp_tran.sprint()),UVM_LOW)
                      `uvm_info(get_type_name(),$psprintf("the actual TRANS is\n%0s",act_pkt.sprint()),UVM_LOW)
                   end
               end
            end
        end

        if(tmp_tran == null) begin
           if(cfg.latency_mode==glb_dec::LATENCY) begin
              if(cyc_cnt>cfg.delay_cyc) begin
                 `uvm_error(get_type_name(),$psprintf("logic output is earlier than testbench, actual pkt is\n%s!",act_pkt.sprint()));
                 foreach(expect_queue[i]) begin
                     $cast(exp_pkt, expect_queue[i].clone());
                     if(act_pkt.stream_id == exp_pkt.stream_id) begin
                        `uvm_info(get_type_name(),$psprintf("RTL residue packet is \n%s!", exp_pkt.sprint()), UVM_MEDIUM);
                     end
                 end
                 return;
              end
              else begin
                 cyc_cnt ++;
                 #1ns;
              end
           end
           else begin
              `uvm_error(get_type_name(),$psprintf("expect pkt not found, actual pkt is\n%s!",act_pkt.sprint()));
              return;
           end
        end
        else begin
            cyc_cnt = 0;
            actual_queue.pop_front();
        end
    end
endtask

task multi_stream_scoreboard::expect_out_order();

    while(1) begin
        wait(actual_queue.size()>0);
        $cast(act_pkt, actual_queue[0]);

        //search by channel
        tmp_tran = null;
        for(int i=0;i<expect_queue.size() && expect_queue.size()>0;i++) begin
            $cast(exp_pkt, expect_queue[i].clone());

            if((act_pkt.stream_id != exp_pkt.stream_id)||exp_pkt == null) begin
               tmp_tran = null;
            end
            else begin
               $cast(tmp_tran , expect_queue[i].clone);

               if(act_pkt.compare(tmp_tran))begin 
                   n_matched[act_pkt.stream_id] ++;
                   `uvm_info(get_type_name(),"TRANS Matched in expect_out_order",UVM_LOW);
                   expect_queue.delete(i--);
                   break;
               end
               else begin
                   `uvm_info(get_type_name(),$psprintf("expect pkt is \n%s while actual pkt is\n%s",exp_pkt.sprint(),act_pkt.sprint()),UVM_MEDIUM);
                   tmp_tran = null;
               end
            end
        end

        if(tmp_tran == null) begin
           if(cfg.latency_mode==glb_dec::LATENCY) begin
              if(cyc_cnt>cfg.delay_cyc) begin
                 `uvm_error(get_type_name(),$psprintf("logic output is earlier than testbench, actual pkt is\n%s",act_pkt.sprint()));
                 foreach(expect_queue[i]) begin
                     $cast(exp_pkt, expect_queue[i].clone());
                     `uvm_info(get_type_name(),$psprintf("RTL residue packet is \n%s", exp_pkt.sprint()), UVM_MEDIUM);
                 end
                 return;
              end
              else begin
                 cyc_cnt ++;
                 #1ns;
              end
           end
           else begin
              `uvm_error(get_type_name(),$psprintf("expect pkt not found, actual pkt is\n%s",act_pkt.sprint()));
              return;
           end
        end
        else begin
            cyc_cnt = 0;
            actual_queue.pop_front();
        end
    end
endtask

function void multi_stream_scoreboard::scoreboard_report();
    string str_tmp = "";
    string str = "";
    bit[7:0] chan_oft;

    str = get_name();
    if (str.len() < 30) str = {str, {(30 - str.len()){" "}}};
    else if (str.len() > 30) str = str.substr(0, 29);

    foreach(expect_queue[i]) begin
       `uvm_info(get_type_name(),$psprintf("[ORPHAN] The %0dth packet is \n%s",i,expect_queue[i].sprint()),UVM_MEDIUM);
        n_orphan[expect_queue[i].stream_id] += 1;
    end
    expect_queue.delete();

    $sformat(str_tmp, "\n\n+--------------------------------+------+------+------+------+------+------+\n");
    $sformat(str_tmp, "%s| %s |%s|%s|%s|%s|%s|%s|\n", str_tmp, str,
           "Insert", "Actual", "Matchd", "MsMtch", "Droppd", "Orphan");        
    $sformat(str_tmp, "%s+--------------------------------+------+------+------+------+------+------+\n", str_tmp);

    if(n_expect.first(chan_oft)) do
    begin
        str = $psprintf("%0d->%0d",chan_oft,chan_oft);
        if (str.len() < 30) str = {str, {(30 - str.len()){" "}}};
        else if (str.len() > 30) str = str.substr(0, 29);

        $sformat(str_tmp, "%s| %0s | %04d | %04d | %04d | %04d | %04d | %04d |\n",
                           str_tmp, str, this.n_expect[chan_oft], this.n_actual[chan_oft], this.n_matched[chan_oft], this.n_mismatched[chan_oft],this.n_dropped[chan_oft], this.n_orphan[chan_oft]);
        $sformat(str_tmp, "%s+--------------------------------+------+------+------+------+------+------+\n", str_tmp);

        if(n_actual[chan_oft]==0 && cfg.actual_zero_report_err_enable==1) `uvm_error(get_type_name(),$psprintf("Pkt all missed, Please check!"))
        if(n_matched[chan_oft]==0 && cfg.actual_zero_report_err_enable==1) `uvm_error(get_type_name(),$psprintf("Pkt all dropped, Please check!"))

        if(cfg.comp_mode==glb_dec::IN_ORDER || cfg.comp_mode==glb_dec::OUT_OF_ORDER) begin
           if(n_expect[chan_oft] != n_actual[chan_oft] || n_orphan[chan_oft]>0)
           begin
               `uvm_error("TRACE",$psprintf("u_sb of chan%0d:n_expect(%0d),n_actual(%0d),n_matched(%0d),n_mismatched(%0d),n_dropped(%0d),n_orphan(%0d)",
                                                    chan_oft, n_expect[chan_oft],n_actual[chan_oft],n_matched[chan_oft],n_mismatched[chan_oft],n_dropped[chan_oft],n_orphan[chan_oft]));
           end
        end
        else begin
           if(n_expect[chan_oft] != n_matched[chan_oft] + n_dropped[chan_oft] + n_orphan[chan_oft])
           begin
               `uvm_error("TRACE",$psprintf("u_sb of chan%0d:n_expect(%0d),n_actual(%0d),n_matched(%0d),n_mismatched(%0d),n_dropped(%0d),n_orphan(%0d)",
                                                    chan_oft, n_expect[chan_oft],n_actual[chan_oft],n_matched[chan_oft],n_mismatched[chan_oft],n_dropped[chan_oft],n_orphan[chan_oft]));
           end
        end
    end
    while(n_expect.next(chan_oft));

    `uvm_info(get_type_name(), $sformatf("%s", str_tmp), UVM_LOW);

endfunction

function void multi_stream_scoreboard::report_phase(uvm_phase phase);
    scoreboard_report();
endfunction: report_phase

function void multi_stream_scoreboard::flush();
    //reset all statistic
    n_matched.delete;
    n_mismatched.delete;
    n_dropped.delete;
    n_expect.delete;
    n_actual.delete;
    n_orphan.delete;

    expect_queue.delete();
    actual_queue.delete();
endfunction: flush

`endif


