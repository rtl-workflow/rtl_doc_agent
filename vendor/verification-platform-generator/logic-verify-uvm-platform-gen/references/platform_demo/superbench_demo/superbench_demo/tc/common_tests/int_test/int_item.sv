// **********************************************************************
// Copyright(c) 2018-2021, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : int_item.sv
// Author         : wenzheng/w00580166
// Date           : 2021/05/20
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2021/05/20 wenzheng  1.0 Create
// 2022/10/10 yangyang  1.1 Modify
// 
// ***********************************************************************
// DEFINE 
// ***********************************************************************
// Module       : 
// Called by    : 
// ***********************************************************************
// $Log: 
// 
// ***********************************************************************

`ifndef INT_ITEM__SV
`define INT_ITEM__SV
class int_item extends uvm_object                                                                   ;
    string name                                                                                     ;
    string signal                                                                                   ;
    bit    signal_value                                                                             ;
    int    exp_mirr_value                                                                           ;
    uvm_reg_field enbreg                                                                            ;
    uvm_reg_field hisreg                                                                            ;
    uvm_reg_field almreg                                                                            ;
    uvm_reg_field frcreg                                                                            ;
    int en_field_bits =-1                                                                           ;
    int his_field_bits=-1                                                                           ;
    int alm_field_bits=-1                                                                           ;
    int frc_field_bits=-1                                                                           ;
    uvm_reg  reg_list[$]                                                                            ;
    int_item m_children[$]                                                                          ;
    int_item parent                                                                                 ;
    //==============================================================================================/
    `uvm_object_utils_begin(int_item)
        `uvm_field_string(name,UVM_ALL_ON)
        `uvm_field_string(signal,UVM_ALL_ON)
        `uvm_field_object(enbreg,UVM_ALL_ON)
        `uvm_field_object(hisreg,UVM_ALL_ON)
        `uvm_field_object(almreg,UVM_ALL_ON)
        `uvm_field_object(frcreg,UVM_ALL_ON)
        `uvm_field_queue_object(m_children,UVM_ALL_ON)
    `uvm_object_utils_end
    //==============================================================================================/
    extern function new(string name="int_item")                                                     ;
    extern function int_item find_item_children(string children_name)                               ;
    extern function bit configure(string name,string children[$],
                                  string signal,uvm_reg_field enbreg,hisreg,almreg,frcreg,
                                  int en_bits=-1,his_bits=-1,alm_bits=-1,frc_bits=-1)               ;
    extern task int_check(int_item children,bit value,bit reg_value)                                ;
    extern task int_test()                                                                          ;
    extern task clear_all_alarm();
    extern function print_int(int level);
endclass:int_item
//==================================================================================================
//
//==================================================================================================
function int_item::print_int(int level);
    //$display("%s",{{level{" "}},"+",this.name});

    //============================================
    // modified by z00509815 
    // to adapt Excel VB process format
    //============================================ begin
    string          en_fullname     ;
    string          int_fullname    ;
    string          en_name         ;
    string          int_name        ;
    int             int_bits        ;
    uvm_reg_field   intreg          ;

    if(hisreg == null) begin
        intreg = this.almreg;
        int_bits = this.alm_field_bits;
    end
    else begin
        intreg = this.hisreg;
        int_bits = this.his_field_bits;
    end
    
    if(this.enbreg != null) en_fullname  = this.enbreg.get_full_name();
    if(intreg != null)      int_fullname = intreg.get_full_name();
    `uvm_info(get_type_name(),$psprintf("print_int1:%s %s %s %s %s %d",this.signal,en_fullname,int_fullname,en_name,int_name,int_bits),UVM_NONE)

    `define MODIFY_REG_FLD_EXPRESS(_fullname,_mod_name,_bits)\
    begin\
        string  splitname[$];\
        string  splitarray[$];\
        string  final_name;\
        uvm_split_string(``_fullname, ".", splitname);\
        uvm_split_string(splitname[2], "[", splitarray);\
        final_name = {splitname[1],".",splitname[3]};\
        for(int i=1; i<splitarray.size; i++) final_name = {final_name,"[",splitarray[i]};\
        if(``_bits != -1) final_name = {final_name,$psprintf("[%0d:%0d]",``_bits,``_bits)};\
        ``_mod_name = final_name;\
    end

    en_name = "null";
    int_name = "null";
    if(this.enbreg != null) `MODIFY_REG_FLD_EXPRESS(en_fullname,en_name,this.en_field_bits)
    if(intreg != null)      `MODIFY_REG_FLD_EXPRESS(int_fullname,int_name,int_bits)
    `uvm_info(get_type_name(),$psprintf("print_int2:%s %s %s %s %s %d",this.signal,en_fullname,int_fullname,en_name,int_name,int_bits),UVM_NONE)

    `undef MODIFY_REG_FLD_EXPRESS

    $display("%s",{{level{$psprintf("null\tnull\t")}},en_name,$psprintf("\t"),int_name});
    //============================================ end

    foreach(m_children[i])begin
        m_children[i].print_int(level+1);
    end
endfunction
//==============================================================================================/
function int_item::new(string name="int_item")                                                      ;
    super.new(name)                                                                                 ;
    this.name=name                                                                                  ;
endfunction:new
//==================================================================================================
//
//==================================================================================================
function int_item int_item::find_item_children(string children_name)                                ;
    find_item_children=null                                                                         ;
    foreach(this.m_children[i])begin
         `uvm_info(get_type_name(),$psprintf("m_children_2:%d %s",i,this.m_children[i].name),UVM_NONE)
        if(this.m_children[i].name==children_name) find_item_children= this.m_children[i]           ;
        `uvm_info(get_type_name(),$psprintf("m_children_2:%d %s",i,this.m_children[i].name),UVM_NONE)
        if(find_item_children!=null) break                                                          ;
    end
    return find_item_children                                                                       ;
endfunction:find_item_children
//==================================================================================================
//
//==================================================================================================
function bit int_item::configure(string name,string children[$],string signal,uvm_reg_field enbreg,hisreg,almreg,frcreg,
int en_bits=-1,his_bits=-1,alm_bits=-1,frc_bits=-1);
    int_item vr_item                                                                                ;
    uvm_reg  int_reg                                                                                ;
    string v_children                                                                               ;
    if(this.name==name&&children.size()==0) begin
       this.name=name;this.signal=signal;this.enbreg=enbreg;this.hisreg=hisreg;this.almreg=almreg;this.frcreg=frcreg;
       this.en_field_bits=en_bits;this.his_field_bits=his_bits;this.alm_field_bits=alm_bits;this.frc_field_bits=frc_bits;
       `uvm_info(get_type_name(),$psprintf("name :%d, %s; %s",this.m_children.size(),name,signal),UVM_NONE)

       if(this.enbreg!=null)begin
           int_reg=this.enbreg.get_parent()                                                         ;
           if((int_reg inside {this.parent.reg_list})==0) this.parent.reg_list.push_back(int_reg)   ;
       end
       if(this.frcreg!=null)begin
           int_reg=this.frcreg.get_parent()                                                         ;
           if((int_reg inside {this.parent.reg_list})==0) this.parent.reg_list.push_back(int_reg)   ;
       end
    end
    else if(this.name==name)begin
        v_children=children.pop_front()                                                             ;
        vr_item=this.find_item_children(v_children)                                                 ;
//        `uvm_info(get_type_name(),$psprintf("children_: %s %s %s",name,vr_item.name,v_children),UVM_NONE)
        if(vr_item==null)begin
            vr_item=new(v_children); this.m_children.push_back(vr_item)                             ;
            `uvm_info(get_type_name(),$psprintf("vr_item:%d, %s; %s; %s",this.m_children.size(),name,this.name,v_children),UVM_NONE)
 
            vr_item.parent=this                                                                     ;
        end
        vr_item.configure(v_children,children,signal,enbreg,hisreg,almreg,frcreg,en_bits,his_bits,alm_bits,frc_bits);
    end
endfunction:configure
//==================================================================================================
//
//==================================================================================================
task int_item::clear_all_alarm();
    uvm_status_e   status                                                                           ;
    uvm_reg        item_reg                                                                         ;
    int value;
    if(this.m_children.size()==0)begin
        uvm_hdl_force(this.signal,0);
        #1000;
    `ifdef FOR_INT_SKIP_READ_CLEAR_SIM
    `else
        if(this.hisreg!=null)begin
            item_reg=this.hisreg.get_parent();
            item_reg.write(status,32'hffffffff,UVM_FRONTDOOR) ;
        end
        if(this.almreg!=null)begin
            item_reg=this.almreg.get_parent();
            item_reg.write(status,32'hffffffff,UVM_FRONTDOOR) ;
        end
    `endif
        `uvm_info(get_type_name(),$psprintf("clear alarm:%s",this.signal),UVM_NONE)
        return;
    end
    else foreach(this.m_children[i])begin
        this.m_children[i].clear_all_alarm();
        `uvm_info(get_type_name(),$psprintf("m_children_0:%d %s",i,this.m_children[i].name),UVM_NONE)
        `uvm_info(get_type_name(),$psprintf("clear alarm:%d, %s",this.m_children.size(),this.signal),UVM_NONE)
    end
endtask:clear_all_alarm
//==================================================================================================
//
//==================================================================================================
task int_item::int_test()                                                                           ;
    uvm_status_e status                                                                             ;
    int children_size                                                                               ;
    bit[31:0]    value                                                                              ;
    uvm_reg        item_reg                                                                         ;
    if(this.m_children.size()==0) return                                                            ;
    else foreach(this.m_children[i])begin
        children_size=this.m_children.size()                                                        ;
        `uvm_info(get_type_name(),$psprintf("m_children_1:%d, %d, %s; %s",i,children_size,this.m_children[i].name,this.m_children[i].signal),UVM_NONE)
        //=========================================================================================//
        //==================================test int froce signal func=============================//      
        
        //*****************step 1: open int_enable reg to 1, froce int source signal to 1  ********// 
        for(int j=0;j<children_size;j++)begin
            if(i==j&&this.m_children[j].enbreg!=null)begin 
                if(this.m_children[j].en_field_bits==-1) this.m_children[j].enbreg.set(1)           ;
                else this.m_children[j].enbreg.set((1<<this.m_children[j].en_field_bits))           ;
                `uvm_info(get_type_name(),$psprintf("m_children_2:%d %d %s; %s",i,j,this.m_children[j].name,this.m_children[i].signal),UVM_NONE)
                `uvm_info(get_type_name(),$psprintf("enbreg:",this.m_children[j].enbreg.get_name()),UVM_NONE)
            end
            else if( this.m_children[j].enbreg!=null)begin
                if(this.m_children[j].en_field_bits==-1) begin
                    if(this.m_children[j].enbreg.get_name() != this.m_children[i].enbreg.get_name()) begin
                        this.m_children[j].enbreg.set(0)                                            ;
                        `uvm_info(get_type_name(),$psprintf("enbreg.name:%d %d %s",i,j,this.m_children[i].enbreg.get_name()),UVM_NONE)
                    end
                end
                else begin
                    if(this.m_children[j].enbreg.get_name() != this.m_children[i].enbreg.get_name() ||
                       this.m_children[j].en_field_bits         != this.m_children[i].en_field_bits            ) begin
                        value=this.m_children[j].enbreg.get()                                           ;
                        value=value&(~(1<<this.m_children[j].en_field_bits))                            ;
                        `uvm_info(get_type_name(),$psprintf("value: %d, %d",value,this.m_children[j].en_field_bits),UVM_NONE)
                        this.m_children[j].enbreg.set(value)                                            ;
                    end
                end
                `uvm_info(get_type_name(),$psprintf("%d enbreg: ",j,this.m_children[j].enbreg.get_name()),UVM_NONE)
            end
            if(i==j)begin 
                `uvm_info(get_type_name(),$psprintf("%d set %s to 1",j,this.m_children[j].signal),UVM_NONE)
                uvm_hdl_force(this.m_children[j].signal,1)                                     ;
            end
            else begin 
                `uvm_info(get_type_name(),$psprintf("set %s to 0",this.m_children[j].signal),UVM_NONE)
                uvm_hdl_force(this.m_children[j].signal,0)                                          ;
            end
        end
        foreach(this.reg_list[m]) this.reg_list[m].update(status)                                   ;
        //chk int signal is 1,his_int is 1 
        this.int_check(this.m_children[i],1,1)                                                      ;

        //******************************setp 2: close int_eable ,cfg reg to 0  *********************// 
        if(this.m_children[i].enbreg!=null)begin
            `uvm_info(get_type_name(),$psprintf("enb_reg : %s, %d",this.m_children[i].enbreg.get_name(),this.m_children[i].en_field_bits),UVM_NONE)
            if(this.m_children[i].en_field_bits!=-1)begin
                value=this.m_children[i].enbreg.get()                                               ;
                `uvm_info(get_type_name(),$psprintf("en_field_bits : %d, %d",value,(1<<this.m_children[i].en_field_bits)),UVM_NONE)
                value=value&(~(1<<this.m_children[i].en_field_bits))                                ;
                this.m_children[i].enbreg.set(value)                                                ;
            end else this.m_children[i].enbreg.set(0);

            item_reg=this.m_children[i].enbreg.get_parent();
            item_reg.update(status);
            //chk int signal is 0, his_int is 1
            this.int_check(this.m_children[i],0,1)                                                  ;
            `uvm_info(get_type_name(),$psprintf("enbreg : ",this.m_children[i].enbreg.get_name()),UVM_NONE)

        //*****************************setp 3:  open int_eable ,cfg reg to 1  **********************// 
            if(this.m_children[i].en_field_bits!=-1)begin
                this.m_children[i].enbreg.set((1<<this.m_children[i].en_field_bits))                ;
            end else this.m_children[i].enbreg.set(1)                                               ;

            item_reg=this.m_children[i].enbreg.get_parent();
            item_reg.update(status);
            this.int_check(this.m_children[i],1,1)                                                      ;
        end

        //*****************************setp 4:  no release int source,can't W1HC  **********************// 
        if(this.m_children[i].hisreg!=null)begin 
            item_reg=this.m_children[i].hisreg.get_parent()                                         ;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            if(this.m_children[i].his_field_bits == -1) begin
                item_reg.write(status,1);
                exp_mirr_value=1;
            end
            else begin
                item_reg.write(status,(1<<this.m_children[i].his_field_bits));
                exp_mirr_value=1<<this.m_children[i].his_field_bits;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            end
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",this.m_children[i].hisreg.get_name(),this.name),UVM_NONE)
            item_reg.predict(exp_mirr_value);     
            item_reg.mirror(status,UVM_CHECK)                                                       ; 
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            uvm_hdl_read(this.signal,signal_value)                                                  ;
            `uvm_info(get_type_name(),$psprintf("%d ",signal_value),UVM_NONE)
            if(1!=signal_value) `uvm_error("int",$psprintf("int %s wrong",this.name))
        end

        //********************************setp 5: release froce int source signal ******************//
        `uvm_info(get_type_name(),$psprintf("%d: set %s to 0",i,this.m_children[i].signal),UVM_NONE)
        uvm_hdl_force(this.m_children[i].signal,0)                                                  ;
        //write 0,can't clear his int status
        if(this.m_children[i].hisreg!=null)begin 
            item_reg=this.m_children[i].hisreg.get_parent()                                         ;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",this.m_children[i].hisreg.get_name(),this.name),UVM_NONE)
            item_reg.write(status,0);
            if(this.m_children[i].his_field_bits == -1) begin
                exp_mirr_value=1;
            end
            else begin
                exp_mirr_value=1<<this.m_children[i].his_field_bits;
            end
            item_reg.predict(exp_mirr_value);     
            item_reg.mirror(status,UVM_CHECK)                                                       ;
            uvm_hdl_read(this.signal,signal_value)                                                  ;
            `uvm_info(get_type_name(),$psprintf("%d ",signal_value),UVM_NONE)
            if(1!=signal_value) `uvm_error("int",$psprintf("int %s wrong",this.name))
        end
        //write 1 to clear his int ,clear int signal
        this.int_check(this.m_children[i],0,0)                                                      ; 

        if(this.m_children[i].m_children.size()==0) uvm_hdl_force(this.m_children[i].signal,0)      ;
        else uvm_hdl_release(this.m_children[i].signal)                                             ;


        #100;
        //=========================================================================================//
        //==================================test int froce reg func================================//
        for(int k=0;k<children_size;k++)begin
        //*****************setp 1:open int_enable reg to 1,  cfg frc_reg to 1 *********************//
            if(i==k&&this.m_children[k].enbreg!=null)begin 
                if(this.m_children[k].en_field_bits==-1) this.m_children[k].enbreg.set(1)           ;
                else this.m_children[k].enbreg.set((1<<this.m_children[k].en_field_bits))           ;
                `uvm_info(get_type_name(),$psprintf("m_children_2:%d %d %s; %s",i,k,this.m_children[k].name,this.m_children[k].signal),UVM_NONE)
                `uvm_info(get_type_name(),$psprintf("enbreg:",this.m_children[k].enbreg.get_name()),UVM_NONE)
            end
            else if( this.m_children[k].enbreg!=null)begin
                if(this.m_children[k].en_field_bits==-1) begin
                    if(this.m_children[k].enbreg.get_name() != this.m_children[i].enbreg.get_name()) begin
                        this.m_children[k].enbreg.set(0)                                            ;
                        `uvm_info(get_type_name(),$psprintf("enbreg.name:%d %d %s",i,k,this.m_children[k].enbreg.get_name()),UVM_NONE)
                    end
                end
                else begin
                    if(this.m_children[k].enbreg.get_name() != this.m_children[i].enbreg.get_name() ||
                       this.m_children[k].en_field_bits         != this.m_children[i].en_field_bits            ) begin
                        value=this.m_children[k].enbreg.get()                                           ;
                        value=value&(~(1<<this.m_children[k].en_field_bits))                            ;
                        `uvm_info(get_type_name(),$psprintf("value: %d, %d",value,this.m_children[k].en_field_bits),UVM_NONE)
                        this.m_children[k].enbreg.set(value)                                            ;
                    end
                end
                `uvm_info(get_type_name(),$psprintf("%d enbreg: ",k,this.m_children[k].enbreg.get_name()),UVM_NONE)
            end
            //set int froce reg 1
            if(i==k&&this.m_children[k].frcreg!=null)begin 
                if(this.m_children[k].frc_field_bits==-1) this.m_children[k].frcreg.set(1)           ;
                else this.m_children[k].frcreg.set((1<<this.m_children[k].frc_field_bits))           ;
                `uvm_info(get_type_name(),$psprintf("m_children_2:%d %d %s; %s",i,k,this.m_children[k].name,this.m_children[k].signal),UVM_NONE)
                `uvm_info(get_type_name(),$psprintf("frcreg:",this.m_children[k].frcreg.get_name()),UVM_NONE)
                `uvm_info(get_type_name(),$psprintf("frcreg: %d",this.m_children[k].frc_field_bits),UVM_NONE)
            end
            else if( this.m_children[k].frcreg!=null)begin
                if(this.m_children[k].frc_field_bits==-1) begin
                    if(this.m_children[k].frcreg.get_name() != this.m_children[i].frcreg.get_name()) begin
                        this.m_children[k].frcreg.set(0)                                            ;
                        `uvm_info(get_type_name(),$psprintf("frcreg.name:%d %d %s",i,k,this.m_children[k].frcreg.get_name()),UVM_NONE)
                    end
                end
                else begin
                    if(this.m_children[k].frcreg.get_name() != this.m_children[i].frcreg.get_name() ||
                       this.m_children[k].frc_field_bits         != this.m_children[i].frc_field_bits            ) begin
                        value=this.m_children[k].frcreg.get()                                       ;
                        value=value&(~(1<<this.m_children[k].frc_field_bits))                       ;
                        `uvm_info(get_type_name(),$psprintf("value: %d, %d",value,this.m_children[k].frc_field_bits),UVM_NONE)
                        this.m_children[k].frcreg.set(value)                                        ;
                    end
                end
                `uvm_info(get_type_name(),$psprintf("%d frcreg: ",k,this.m_children[k].frcreg.get_name()),UVM_NONE)
            end
        end
        foreach(this.reg_list[m]) this.reg_list[m].update(status)                                   ;
        //chk int signal is 1,his_int is 1 
        this.int_check(this.m_children[i],1,1)                                                      ;
        
        //*****************************************************************************************//
        //******************************setp 2: close int_eable ,cfg reg to 0  ********************// 
        if(this.m_children[i].enbreg!=null)begin
            `uvm_info(get_type_name(),$psprintf("enb_reg : %s, %d",this.m_children[i].enbreg.get_name(),this.m_children[i].en_field_bits),UVM_NONE)
            if(this.m_children[i].en_field_bits!=-1)begin
                value=this.m_children[i].enbreg.get()                                               ;
                `uvm_info(get_type_name(),$psprintf("en_field_bits : %d, %d",value,(1<<this.m_children[i].en_field_bits)),UVM_NONE)
                value=value&(~(1<<this.m_children[i].en_field_bits))                                ;
                this.m_children[i].enbreg.set(value)                                                ;
            end else this.m_children[i].enbreg.set(0);

            item_reg=this.m_children[i].enbreg.get_parent();
            item_reg.update(status);
            this.int_check(this.m_children[i],0,1)                                                  ;
            `uvm_info(get_type_name(),$psprintf("enbreg : ",this.m_children[i].enbreg.get_name()),UVM_NONE)
        
            //*****************************setp 3:  open int_eable ,cfg reg to 1  **********************// 
            if(this.m_children[i].en_field_bits!=-1)begin
                this.m_children[i].enbreg.set((1<<this.m_children[i].en_field_bits))                ;
            end else this.m_children[i].enbreg.set(1)                                               ;

            item_reg=this.m_children[i].enbreg.get_parent();
            item_reg.update(status);
            this.int_check(this.m_children[i],1,1)                                                  ;
        end

        //*****************************setp 4:  no release int source,can't W1HC  **********************// 
        if(this.m_children[i].hisreg!=null)begin 
            item_reg=this.m_children[i].hisreg.get_parent()                                         ;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            if(this.m_children[i].his_field_bits == -1) begin
                item_reg.write(status,1);
                exp_mirr_value=1;
            end
            else begin
                item_reg.write(status,(1<<this.m_children[i].his_field_bits));
                exp_mirr_value=(1<<this.m_children[i].his_field_bits);
            end
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",this.m_children[i].hisreg.get_name(),this.name),UVM_NONE)
            item_reg.predict(exp_mirr_value);     
            item_reg.mirror(status,UVM_CHECK)                                                       ; 
            uvm_hdl_read(this.signal,signal_value)                                                  ;
            `uvm_info(get_type_name(),$psprintf("%d ",signal_value),UVM_NONE)
            if(1!=signal_value) `uvm_error("int",$psprintf("int %s wrong",this.name))
        end


        //********************************setp 5: cfg froce reg to 0  **********************************//
        if(this.m_children[i].frcreg!=null)begin
            this.m_children[i].frcreg.set(0)                                                         ;
            `uvm_info(get_type_name(),$psprintf("frcreg.name:%d  %s",i,this.m_children[i].frcreg.get_name()),UVM_NONE)
        end
        item_reg=this.m_children[i].frcreg.get_parent();
        item_reg.update(status);
        //write 0,can't clear his int status
        if(this.m_children[i].hisreg!=null)begin 
            item_reg=this.m_children[i].hisreg.get_parent()                                         ;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",this.m_children[i].hisreg.get_name(),this.name),UVM_NONE)
            item_reg.write(status,0);
            if(this.m_children[i].his_field_bits == -1) begin
                exp_mirr_value=1;
            end
            else begin
                exp_mirr_value=1<<this.m_children[i].his_field_bits;
            end
            item_reg.predict(exp_mirr_value);     
            item_reg.mirror(status,UVM_CHECK)                                                       ;
            uvm_hdl_read(this.signal,signal_value)                                                  ;
            `uvm_info(get_type_name(),$psprintf("%d ",signal_value),UVM_NONE)
            if(1!=signal_value) `uvm_error("int",$psprintf("int %s wrong",this.name))
        end
        //write 1 to clear his int ,clear int signal
        this.int_check(this.m_children[i],0,0)                                                      ;
        

        //=========================================================================================//
        //==================================continue test next int tree============================//
        #100;
        this.m_children[i].int_test()                                                               ;
    end
endtask:int_test
//==================================================================================================
//
//==================================================================================================
task int_item::int_check(int_item children,bit value,bit reg_value)                                 ;
    uvm_status_e   status                                                                           ;
    uvm_reg        item_reg                                                                         ;
    bit            read_value;
    int            desired_value                                                                    ;
    //*********************************************************************************************//
    //stb_realtime.delay(300)                                                                         ;
    #300;
    //*********************************************************************************************//
    if(children.hisreg!=null)begin 
        if(children.his_field_bits==-1) desired_value=reg_value;
        else  desired_value=(reg_value==1) ? (1<<children.his_field_bits) : 0                       ;
        `uvm_info(get_type_name(),$psprintf("hisreg:%d, %s, %s",desired_value,children.hisreg.get_name(),this.signal),UVM_NONE)
        item_reg=children.hisreg.get_parent()                                                       ;
        `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",item_reg.get_name(),this.name),UVM_NONE)
        item_reg.predict(desired_value);
        if(reg_value==1) item_reg.mirror(status,UVM_CHECK)                                          ;
        else begin
            //item_reg.mirror(status,UVM_NO_CHECK); //rc
            //item_reg.set(1);                        //wc
            //item_reg.update(status);
            if(children.his_field_bits == -1) begin
                item_reg.write(status,1);
            end
            else begin
                item_reg.write(status,(1<<children.his_field_bits));
            end
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",children.hisreg.get_name(),this.name),UVM_NONE)
            children.hisreg.predict(0)                                                              ;
            `uvm_info(get_type_name(),$psprintf("item_reg:%s, %s",children.hisreg.get_name(),this.name),UVM_NONE)
            item_reg.mirror(status,UVM_CHECK   )                                                    ;
        end
    end
    //---------------------------------------------------------------------------------------------//
    if(children.almreg!=null)begin
        item_reg=children.almreg.get_parent()                                                       ;
        if(children.alm_field_bits==-1) desired_value=value;
        else desired_value=(value==1) ? (1<<children.alm_field_bits) : 0                        ;
        children.almreg.predict(value)                                                      ;
        item_reg.mirror(status,UVM_CHECK)                                                           ;
    end
    //*********************************************************************************************//
    `uvm_info(get_type_name(),$psprintf("start check %s",this.signal),UVM_NONE)
    uvm_hdl_read(this.signal,read_value)                                                            ;
    `uvm_info(get_type_name(),$psprintf("%d %d",value,read_value),UVM_NONE)
    if(value!=read_value) `uvm_error("int",$psprintf("int %s wrong",this.name))
    if(this.parent!=null ) this.parent.int_check(this,value,reg_value&value)                        ;
    //*********************************************************************************************//
endtask:int_check
`endif //INT_ITEM__SV
