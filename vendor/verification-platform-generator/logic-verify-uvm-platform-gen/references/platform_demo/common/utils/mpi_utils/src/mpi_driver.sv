//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_driver.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0 
// ABSTRACT      : Switch stb_rw_sequence_item to corresponding read/write command
//
//******************************************************************************

`ifndef MPI_DRIVER__SV
`define MPI_DRIVER__SV

/** \brief mpi_driver class
    Translate the stb_rw_sequence_item or its extention transactions into the timing traffic
    which the DUT module can recognise
*/
class mpi_driver extends stb_driver #(virtual mpi_interface);

    mpi_driver_cfg                           cfg;     ///< Configuration for mpi_driver

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

    `uvm_component_utils_begin(mpi_driver)
        `uvm_field_object(cfg, UVM_ALL_ON)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//        
    `uvm_component_utils_end

    /** \brief new
    Constructor
    */
    extern function new(string              name,
                        uvm_component       parent            
                        );

    /** \brief build_phase
    Calls super.build_phase(phase) to enable automatic get config and create object 
    */    
    extern virtual function void build_phase(uvm_phase phase);

    /** \brief run_phase
    Components implement behavior that is exhibited for the entire run-time, across the various run-time phases
    */
    extern virtual task run_phase(uvm_phase phase);

    /** \brief reset
    Reset mpi_interface input signals
    */
    extern virtual task reset();

    /** \brief send_stimulus_data
    Get stimulus data from seq_item_port, drive stimulus data to DUT interface
    */
    extern virtual task send_stimulus_data(); 

    /** \brief cpu_single_write
    The handle of single timing write, Pack logic signal to physical signal
    Drive the physical signal onto the bus
    This task performs the following functions until stopped.
    */
    extern virtual task cpu_single_write(input mpi_xaction tr);

    /** \brief cpu_single_read
    The handle of single timing read, Pack logic signal to physical signal
    Drive the physical signal onto the bus
    This task performs the following functions until stopped.
    */
    extern virtual task cpu_single_read(ref mpi_xaction tr);

    /** \brief cpu_burst_write
    The handle of burst timing write, Pack logic signal to physical signal
    Drive the physical signal onto the bus
    This task performs the following functions until stopped.
    */
    extern virtual task cpu_burst_write(input mpi_xaction tr);

    /** \brief cpu_burst_read
    The handle of burst timing read, Pack logic signal to physical signal
    Drive the physical signal onto the bus
    This task performs the following functions until stopped.
    */
    extern virtual task cpu_burst_read(ref mpi_xaction tr);

    /** \brief task drv_random
    Drive random value to DUT interface when driver can't get transaction from input transaction queue
    */
    extern virtual task drv_random();

    //------------------------------------------------------------------------//
    // Define the member task/function base on project requirement            //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: mpi_driver

function mpi_driver::new(string        name,
                        uvm_component  parent
                        );

    super.new(name, parent);

endfunction: new

function void mpi_driver::build_phase(uvm_phase phase);

    super.build_phase(phase);
    
    if(this.cfg == null) begin
        this.cfg = mpi_driver_cfg::type_id::create("cfg", this);
        `uvm_info(get_type_name(), "build_phase(): Randomizing mpi_driver configuration object", UVM_MEDIUM);
        if (!this.cfg.randomize()) begin
            `uvm_fatal(get_type_name(),"build_phase(): cfg.randomize() call failed!");
        end
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): cfg.sprint(): \n%s", this.cfg.sprint()), UVM_HIGH);

endfunction: build_phase

task mpi_driver::reset();

    //------------------------------------------------------------------------//
    //  Extend reset() base on project requirement                            //
    //------------------------------------------------------------------------//    
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endtask: reset

task mpi_driver::run_phase(uvm_phase phase);

    super.run_phase(phase);

    `uvm_info(get_type_name(), "run_phase(): mpi_driver run_phase is running", UVM_MEDIUM);
    this.reset();
    this.send_stimulus_data();
    
endtask: run_phase

task mpi_driver::send_stimulus_data();

    mpi_xaction drv_tr;  
    mpi_xaction out_tr;

    while(1) begin
         
        uvm_wait_for_nba_region();
        if(this.seq_item_port.has_do_available()) begin
            this.seq_item_port.get_next_item(req);
            if(!$cast(drv_tr, req)) begin
                `uvm_fatal(get_type_name(), "send_stimulus_data(): req is not a mpi_xactions type or its extension");
            end

            //----------------------------------------------------------------//
            // 1. If this VIP support MASTER_NO_MONITOR work mode, user should// 
            //    write transaction in out_port; User can decide when and     // 
            //    where write trasaction                                      //
            // 2. If this VIP don't support MASTER_NO_MONITOR work mode,      //
            //    user can delete code which write trasaction in out_port;    //
            //    But for utils_unit_test environment which use the           //
            //    VIP MASTER_NO_MONITOR work mode, so this VIP can't run      //
            //    utils_unit_test environment.                                //
            //----------------------------------------------------------------//
            assert($cast(out_tr, drv_tr.clone()));
            this.out_port.write(out_tr); 

            case (drv_tr.op_type) 
                uvm_pkg::UVM_READ: begin
                    cpu_single_read(drv_tr);
                end
  
                uvm_pkg::UVM_BURST_READ: begin
                    cpu_burst_read(drv_tr);
                end

                uvm_pkg::UVM_WRITE: begin 
                    cpu_single_write(drv_tr);    
                end

                uvm_pkg::UVM_BURST_WRITE: begin
                    cpu_burst_write(drv_tr);
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("send_stimulus_data(): The option is not read or write"));             
                end        
            endcase

            this.seq_item_port.item_done();
            `uvm_info(get_type_name(), $sformatf("send_stimulus_data(): Output the drv_tr: \n%s ", drv_tr.sprint()), UVM_DEBUG);
        end
        else begin
            drv_random();
        end
    end

endtask: send_stimulus_data

task mpi_driver::cpu_single_write(input mpi_xaction tr);

    //------------------------------------------------------------------------//
    // Add the timing handle in cpu_single_write base on project requirement  //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // @bus.drv_mp.drv_cb;
    // bus.drv_mp.drv_cb.i_addr <='hx;
    #10ns;        // Add the time only for environment run, user can delete it
    //-----------------------------Coding end---------------------------------//

endtask: cpu_single_write

task mpi_driver::cpu_single_read(ref mpi_xaction tr);

    //------------------------------------------------------------------------//
    // Add the timing handle in cpu_single_read base on project requirement   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // @bus.drv_mp.drv_cb;
    // bus.drv_mp.drv_cb.i_addr <='hx;
    #10ns;        // Add the time only for environment run, user can delete it
    //-----------------------------Coding end---------------------------------//

endtask: cpu_single_read

task mpi_driver::cpu_burst_write(input mpi_xaction tr);

    //------------------------------------------------------------------------//
    // Add the timing handle in cpu_burst_write base on project requirement   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endtask: cpu_burst_write

task mpi_driver::cpu_burst_read(ref mpi_xaction tr);

    //------------------------------------------------------------------------//
    // Add the timing handle in cpu_burst_read base on project requirement    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endtask: cpu_burst_read

task mpi_driver::drv_random();

    //------------------------------------------------------------------------//
    // User define which bus signals give random value                        //
    // and which bus signals give fixed value                                 //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // @bus.drv_mp.drv_cb;
    // bus.drv_mp.drv_cb.addr <= $urandom();    
    #10ns;       // Add the time only for environment run, user can delete it
    //-----------------------------Coding end---------------------------------//

endtask:drv_random

`endif

