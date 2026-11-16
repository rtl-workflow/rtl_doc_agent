config topcfg;
    
    design tb_top stb_realtime;
    //instance tb_top.U_BLK_B liblist DUT;
    partition instance tb_top;//partition instance tb_top.XXX
    partition package uvm_pkg;

    default liblist DEFAULT;

    
endconfig
