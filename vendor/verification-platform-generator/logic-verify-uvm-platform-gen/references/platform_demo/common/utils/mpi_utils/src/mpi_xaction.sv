//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_xaction.sv
// AUTHOR        : x00508178 
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Derive class extends stb_rw_sequence_item
//
//******************************************************************************

`ifndef MPI_XACTION__SV
`define MPI_XACTION__SV

/** \brief mpi_xaction class
    Extension cpu class to generate cpu data
*/
class mpi_xaction extends stb_rw_sequence_item;

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // rand bit [mpi_dec::OPTION_GAP_WIDTH-1 : 0]  rd2rd_idle;  ///< The time gap between read and read
    // rand bit [mpi_dec::OPTION_GAP_WIDTH-1 : 0]  rd2wr_idle;  ///< The time gap between read and write
    // rand bit [mpi_dec::OPTION_GAP_WIDTH-1 : 0]  wr2wr_idle;  ///< The time gap between write and write
    //-----------------------------Coding end---------------------------------//

    //------------------------------------------------------------------------//
    // Declare the constraints of variables                                   //
    // Constrain name tailer need add _cons                                   // 
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // constraint default_cons;
    //-----------------------------Coding end---------------------------------//

    `uvm_object_utils_begin(mpi_xaction)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//
        // `uvm_field_int(rd2rd_idle, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
        // `uvm_field_int(rd2wr_idle, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
        // `uvm_field_int(wr2wr_idle, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
        //-------------------------Coding end---------------------------------//      
    `uvm_object_utils_end

    /** \brief new()
    Constructor
    */
    extern function new(string name = "mpi_xaction");

    /** \brief pre_randomize() 
    Handle random data information before randomize
    */
    extern function void             pre_randomize();

    /** \brief post_randomize() 
    Handle random data information after randomize
    */
    extern function void             post_randomize();

endclass: mpi_xaction

//----------------------------------------------------------------------------//
// Define constraints of the variables base on project requirement            //
// Constrain name tailer need add _cons                                       //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//
// constraint mpi_xaction::default_cons {
//     rd2rd_idle >= 0;
//     rd2wr_idle >= 0;
//     wr2wr_idle >= 0;
//}
//-----------------------------Coding end-------------------------------------//

function mpi_xaction::new(string name = "mpi_xaction");

    super.new(name);

endfunction: new

function void mpi_xaction::pre_randomize();

    //------------------------------------------------------------------------//
    // Extend pre_randomize() base on project requirement                     //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: pre_randomize

function void mpi_xaction::post_randomize();

    //------------------------------------------------------------------------//
    // Extend post_randomize() base on project requirement                    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: post_randomize

`endif

