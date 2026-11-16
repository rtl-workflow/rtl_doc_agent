//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_xaction.sv
// AUTHOR        : x00508178 
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Derive packet class extends stb_sequence_item
//
//******************************************************************************

`ifndef TEST_XACTION__SV
`define TEST_XACTION__SV

/** \brief test_xaction class
    Base packet class to generate packet data
*/
class test_xaction extends stb_sequence_item;

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // rand bit                                sop;               ///< Start of a packet
    // rand bit                                eop;               ///< End of a packet
    // rand int                                pkt_len;           ///< Define the packet length
    // rand int                                pkt_gap[];         ///< The gap between two valid packet data
    // rand int                                pkt_data_cycle;    ///< Number of the cycles of the packet data
    // rand bit                                sop_err;           ///< If value is 1 indicates this packet has sop err,use for drive
    // rand bit                                eop_err;           ///< If value is 1 indicates this packet has eop err,use for drive
    // rand bit [test_dec::PKT_DATA_WIDTH-1:0]   data[];            ///< Packet data array
    // rand bit [test_dec::PKT_EMPTY_WIDTH-1:0]  pkt_empty;         ///< The empty signal width is 4 bits
    //-----------------------------Coding end---------------------------------//

    //------------------------------------------------------------------------//
    // Declare the constraints of variables                                   //
    // Constrain name tailer need add _cons                                   // 
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // constraint pkt_len_cons;                                   ///< Constrain the packet length
    // constraint pkt_data_cycle_cons;                            ///< Constrain the cycle of the packet data   
    // constraint pkt_empty_cons;                                 ///< Constrain the packet empty
    // constraint pkt_gap_cons;                                   ///< Constrain the gap of the packet
    // constraint err_cons;                                       ///< Constrain the error of the packet
    //-----------------------------Coding end---------------------------------//
 
     `uvm_object_utils_begin(test_xaction)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //  
        // 1. By default, the tempate show don't use pack and unpack with     //
        //    field-automation, user should override do_pack fucntion         //
        // 2. If user want to user pack and unpack with field-automation,     //
        //    please delete "| UVM_NOPACK" below.                             //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//
        // `uvm_field_int(sop, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(eop, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(pkt_len, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_array_int(data, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(pkt_empty, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_array_int(pkt_gap, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(pkt_data_cycle, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(sop_err, UVM_ALL_ON | UVM_NOPACK)
        // `uvm_field_int(eop_err, UVM_ALL_ON | UVM_NOPACK)
        //-------------------------Coding end---------------------------------//      
    `uvm_object_utils_end
                                
    /** \brief new()
    Constructor
    */
    extern function new(string name = "test_xaction");

    /** \brief do_pack() 
    Pack as user do 
    */ 
    extern virtual function void do_pack(uvm_packer packer);

    /** \brief do_unpack() 
    Unpack as user do 
    */ 
    extern virtual function void do_unpack(uvm_packer packer);

    /** \brief pre_randomize() 
    Handle random data information before randomize
    */
    extern function void pre_randomize();

    /** \brief post_randomize() 
    Handle random data information after randomize
    */
    extern function void post_randomize();

endclass: test_xaction

//----------------------------------------------------------------------------//
// Define constraints of the variables base on project requirement            //
// Constrain name tailer need add _cons                                       //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//
// constraint test_xaction::pkt_len_cons {
//     pkt_len >= test_dec::MIN_LENGTH;
//     pkt_len <= test_dec::MAX_LENGTH;
// }

// constraint test_xaction::pkt_empty_cons {
//     if(pkt_len%16 != 0)
//         pkt_empty == 16 - pkt_len%16;
//     else        
//         pkt_empty == 0;
// }

// constraint test_xaction::pkt_data_cycle_cons {
//     if(pkt_empty == 0)
//         pkt_data_cycle == pkt_len/16;
//     else 
//         pkt_data_cycle == pkt_len/16 + 1;
// }

// constraint test_xaction::pkt_gap_cons {
//     pkt_gap.size() == pkt_data_cycle;
//     foreach(pkt_gap[i]) pkt_gap[i] == 0;
// }

// constraint test_xaction::err_cons {
//     sop_err     == 0;
//     eop_err     == 0;
// }
//-----------------------------Coding end-------------------------------------//

function test_xaction::new(string name = "test_xaction");

    super.new(name);

endfunction: new

function void test_xaction::do_pack(uvm_packer packer);
    
    super.do_pack(packer);

    //------------------------------------------------------------------------//
    // Extend do_pack() base on project requirement                           //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // packer.pack_field_int(sop, $bits(sop));
    // foreach(data[i]) begin
    //     packer.pack_field_int(data[i], test_dec::PKT_DATA_WIDTH);
    // end
    //-----------------------------Coding end---------------------------------//

endfunction: do_pack

function void test_xaction::do_unpack(uvm_packer packer);

    super.do_unpack(packer);

    //------------------------------------------------------------------------//
    // Extend do_unpack() base on project requirement                         //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // sop = packer.unpack_field_int($bits(sop));
    // foreach(data[i]) begin
    //     data[i] = packer.unpack_field_int(test_dec::PKT_DATA_WIDTH);
    // end
    //-----------------------------Coding end---------------------------------//

endfunction: do_unpack

function void test_xaction::pre_randomize();

    //------------------------------------------------------------------------//
    // Extend pre_randomize() base on project requirement                     //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    
    //-----------------------------Coding end---------------------------------//

endfunction: pre_randomize

function void test_xaction::post_randomize();

    //------------------------------------------------------------------------//
    // Extend post_randomize() base on project requirement                    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: post_randomize

`endif

