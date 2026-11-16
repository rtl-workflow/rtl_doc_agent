//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_driver_cfg.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0 
// ABSTRACT      : The configuration for the mpi interface agent driver
//
//******************************************************************************

`ifndef MPI_DRIVER_CFG__SV
`define MPI_DRIVER_CFG__SV

/** \brief mpi interface agent driver configuration
    This class contains the configuration for the mpi interface agent driver
*/
class mpi_driver_cfg extends uvm_object;

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//
     
    //------------------------------------------------------------------------//
    // Declare the constraints of variables                                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

    `uvm_object_utils_begin(mpi_driver_cfg)
        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//      
    `uvm_object_utils_end

    /** \brief new()
    Constructor
    */
    extern function new(string name = "mpi_driver_cfg");

    /** \brief pre_randomize() 
    Handle random data information before randomize
    */
    extern function void   pre_randomize();

    /** \brief post_randomize() 
    Handle random data information after randomize
    */
    extern function void   post_randomize();

    //------------------------------------------------------------------------//
    // Define the function/task base on project requirement                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: mpi_driver_cfg

//----------------------------------------------------------------------------//
// Define constraints of the variables base on project requirement            //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//

//-----------------------------Coding end-------------------------------------//

function mpi_driver_cfg::new(string name = "mpi_driver_cfg");

    super.new(name);

    //------------------------------------------------------------------------//
    // Add the initial of variables base on project requirement               //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: new

function void mpi_driver_cfg::pre_randomize();

    super.pre_randomize();

    //------------------------------------------------------------------------//
    // Extend pre_randomize() base on project requirement                     //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: pre_randomize

function void mpi_driver_cfg::post_randomize();

    super.post_randomize();

    //------------------------------------------------------------------------//
    // Extend post_randomize() base on project requirement                    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: post_randomize

`endif

