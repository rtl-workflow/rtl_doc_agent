// ---------------------------------------------------------------------
//                 OTN  Verification Project
//======================================================================
// File			:	ovp_broadcast.sv
// Author		:	xiexianchuan  00180017  
// Email        :   xiexianchuan@huawei.com
// Created		:	Tue Sep 19 09:34:23 2017
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
// ---------------------------------------------------------------------
// Description	:
//  1.rcv sqr item,then broadcast item to comps and scoreboard.  only_to_sb=0 ,sqr_in_en=1
//  2.rcv comps item,then send item to scoreboard .              only_to_sb=1
//  3.rcv middle component packet,then broadcast item to next comps and scoreboard.  only_to_sb=0 ,sqr_in_en=0
// ---------------------------------------------------------------------
//function hierarchy:
//  run_phase-> | driver_sqr_item
//              | driver_comps_item
//              | send_only_sb
//****************************************************************************

`ifndef OVP_BROADCAST__SV
`define OVP_BROADCAST__SV

class ovp_broadcast_cfg extends ovp_cfg;
    int   out_port_num;
    bit   only_to_sb;    ///< rcv data from comps,then send data to sb.
    bit   sqr_in_en;     ///< rcv data from sqr or comps,then broadcast data to sb and next comps.
    bit   only_broadcast_en; ///< rcv data form comps,then broadcast by analysys port;
    bit   to_sb_en;      ///< dynamic control to sb or not 

    `uvm_object_utils_begin(ovp_broadcast_cfg)
        `uvm_field_int(display_cfg_en  , UVM_ALL_ON)
        `uvm_field_int(out_port_num    , UVM_ALL_ON)
        `uvm_field_int(only_to_sb      , UVM_ALL_ON)
        `uvm_field_int(sqr_in_en       , UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="ovp_broadcast_cfg");
        super.new(name);
        this.out_port_num = 1;
        this.only_to_sb   = 0;
        this.sqr_in_en    = 1;
        this.to_sb_en     = 1;
    endfunction:new

    function string psdisplay(string prefix = "");
        $sformat(psdisplay, "%s configure:\n",  prefix);
        $sformat(psdisplay, "%s %s\n"        ,  psdisplay, this.sprint());
    endfunction: psdisplay

endclass:ovp_broadcast_cfg

class ovp_broadcast#(type item=uvm_sequence_item)  extends uvm_driver #(uvm_sequence_item);

    ovp_broadcast_cfg                           cfg;
    
    uvm_get_port  #(uvm_sequence_item)          in_port;
    uvm_put_port  #(uvm_sequence_item)          out_port[];
    uvm_analysis_port #(uvm_sequence_item)      sb_port;
    uvm_analysis_port #(uvm_sequence_item)      broad_port[];

    `uvm_component_param_utils_begin(ovp_broadcast#(item))
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

extern function new(string        name="ovp_broadcast",
                    uvm_component parent
                    );

extern virtual function void build_phase(uvm_phase phase);
extern virtual task          run_phase(uvm_phase phase);

extern virtual task          driver_sqr_item();
extern virtual task          driver_comps_item();
extern virtual task          send_only_sb();
extern virtual task          driver_broad_item();

endclass:ovp_broadcast

function ovp_broadcast::new(string        name,
                       uvm_component  parent
                       );

    super.new(name, parent);
endfunction: new

function void ovp_broadcast::build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    `uvm_info(get_type_name(),"build_phase(): ovp_broadcast build_phase is running", UVM_MEDIUM);

    if(this.cfg == null) begin
       if(!uvm_config_db#(ovp_broadcast_cfg)::get(this,"","cfg",cfg)) begin
          `uvm_fatal(get_type_name(),"build_phase(): ovp_broadcast_cfg handler is null");
       end
    end
    if(cfg.display_cfg_en == 1)
        `uvm_info(get_type_name(),this.cfg.psdisplay(""), UVM_NONE);
    
    if(cfg.sqr_in_en == 0) begin
       this.in_port     = new("ovp_broadcast in_port",this);
    end
    this.sb_port        = new("ovp_broadcast sb_port",this);
    if(cfg.only_broadcast_en == 0) begin
        this.out_port       = new[cfg.out_port_num];
        foreach(this.out_port[i]) this.out_port[i]= new($psprintf("ovp_broadcast out_port[%0d]",i),this);
    end
    else begin
        this.broad_port = new[cfg.out_port_num];
        foreach(this.broad_port[i]) this.broad_port[i]= new($psprintf("ovp_broadcast broad_port[%0d]",i),this);
    end

endfunction: build_phase

task ovp_broadcast::run_phase(uvm_phase phase);

    super.run_phase(phase);

    `uvm_info(get_type_name(), "run_phase(): ovp_broadcast run_phase is running", UVM_LOW);
    if(cfg.only_to_sb == 1)
       send_only_sb();
    else if(cfg.sqr_in_en == 1)
       driver_sqr_item();
    else if(cfg.only_broadcast_en == 1)
        driver_broad_item();
    else 
       driver_comps_item();
    
endtask: run_phase

task ovp_broadcast::driver_sqr_item();
    item        in_item;
    item        out_item;
    item        sb_item;
    int         item_cnt=0;
 
    while(1) begin
        uvm_wait_for_nba_region();// #0;
        if(this.seq_item_port.has_do_available()) begin
            this.seq_item_port.get_next_item(req);
            if(!$cast(in_item,req)) begin
                `uvm_fatal(get_type_name(),"ovp_broadcast():req is not a expect type or its extension");
            end

            if(this.cfg.to_sb_en) begin
                sb_item = new();
                $cast(sb_item,in_item.clone());
                this.sb_port.write(sb_item);
            end

            out_item = new();
            $cast(out_item,in_item.clone());

            foreach(this.out_port[i]) begin
               this.out_port[i].put(out_item);
            end    
            this.seq_item_port.item_done();

            `uvm_info(get_type_name(),$psprintf("ovp_broadcast send item[%0d]",item_cnt), UVM_LOW);
            item_cnt ++;
        end
        else 
            #1ns;
   end

endtask:driver_sqr_item

task ovp_broadcast::driver_comps_item();
    uvm_sequence_item   in_item; 
    item                cur_item;
    item        out_item;
    item        sb_item;
    int         item_cnt=0;
 
    while(1) begin
        uvm_wait_for_nba_region();// #0;
        this.in_port.get(in_item);
        if(!$cast(cur_item,in_item)) begin
            `uvm_fatal(get_type_name(),"ovp_broadcast():in_item is not a expect type or its extension");
        end
            
        sb_item = new();
        $cast(sb_item,cur_item.clone());
        this.sb_port.write(sb_item);

        out_item = new();
        $cast(out_item,cur_item.clone());

        foreach(this.out_port[i]) begin
            this.out_port[i].put(out_item);
        end    
        `uvm_info(get_type_name(),$psprintf("ovp_broadcast send item[%0d]",item_cnt), UVM_LOW);
        item_cnt ++;
        
   end

endtask:driver_comps_item

task ovp_broadcast::send_only_sb();
    uvm_sequence_item   in_item; 
    item                cur_item;
    int                 item_cnt=0;

    while(1) begin
        uvm_wait_for_nba_region();// #0;
        this.in_port.get(in_item);
        if(!$cast(cur_item,in_item)) begin
            `uvm_fatal(get_type_name(),"ovp_broadcast():in_item is not a expect type or its extension");
        end
        
        this.sb_port.write(cur_item);
        `uvm_info(get_type_name(),$psprintf("ovp_broadcast nsend item[%0d] only to scoreboard",item_cnt), UVM_NONE);
        item_cnt ++;
    end

endtask:send_only_sb

task ovp_broadcast::driver_broad_item();
    uvm_sequence_item   in_item; 
    item                cur_item;
    item                out_item;
    int                 item_cnt=0;
 
    while(1) begin
        uvm_wait_for_nba_region();// #0;
        this.in_port.get(in_item);
        if(!$cast(cur_item,in_item)) begin
            `uvm_fatal(get_type_name(),"ovp_broadcast():in_item is not a expect type or its extension");
        end
            
        out_item = new();
        $cast(out_item,cur_item.clone());

        foreach(this.broad_port[i]) begin
            this.broad_port[i].write(out_item);
        end    
        `uvm_info(get_type_name(),$psprintf("ovp_broadcast send item[%0d]",item_cnt), UVM_LOW);
        item_cnt ++;
        
   end

endtask:driver_broad_item

`endif
