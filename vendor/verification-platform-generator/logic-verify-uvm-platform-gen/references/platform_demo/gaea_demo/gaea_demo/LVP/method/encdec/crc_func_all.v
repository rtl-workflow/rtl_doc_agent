function [31:0] crc_f;

    input [31:0] din;           //the width of data is [DW-1:0], 0<DW<32
    input [31:0] cin;           //last CRC results,width is [CW-1:0] depend on CRC type
    input [55:0] bit_order;     //"REVERSE","NORMAL"
    input [71:0] crc_type;      //"CRC_32","CRC_CCITT","CRC_16","CRC_12","CRC_8","CRC_7","CRC_4"
    input [4:0]  DW;            //0<DW<32

    reg [31:0] ge   ;
    reg [31:0] ct   ;
    reg fb          ;
    reg [31:0] co   ;
    integer    i    ;
    integer    j    ;
    integer    CW   ;
begin
    if(crc_type == "CRC_32") begin
        ge[31:0] = 32'b00000100110000010001110110110111;
        CW = 32;
    end
    else if(crc_type == "CRC_CCITT") begin
        ge[15:0] = 16'b0001000000100001;
        CW = 16;
    end
    else if(crc_type == "CRC_16") begin
        ge[16:0] = 16'b1000000000000101;
        CW = 16;
    end
    else if(crc_type == "CRC_12") begin
        ge[11:0] = 12'b100000001111;
        CW = 12;
    end
    else if(crc_type == "CRC_8") begin
        ge[7:0] = 8'b00000111;
        //ge[7:0] = 8'b00110001;
        //ge[7:0] = 8'b01011110;
        CW = 8;
    end
    else if(crc_type == "CRC_7") begin
        ge[6:0] = 7'b0001001;
        CW = 7;
    end
    else if(crc_type == "CRC_4") begin
        ge[3:0] = 4'b0011;
        CW = 4;
    end
    else begin
       $display("function crc_f has a error parameter for 'crc_type'");
        ge[31:0] = 32'b00000100110000010001110110110111;
        CW = 32;
    end

    if (bit_order=="NORMAL")
        ct=cin;
    else if(bit_order=="REVERSE") begin
        for (i=0;i<CW;i=i+1)
            ct[i]=cin[CW-1-i];
    end
    else
        $display("function crc_f has a error parameter for 'bit_order'");

    for (i=DW-1;i>=0;i=i-1) begin
        if(bit_order == "NORMAL")
            fb=ct[CW-1] ^ din[i];
        else
            fb=ct[CW-1] ^ din[DW-1-i];

        for (j=CW-1;j>0;j=j-1)
            ct[j]=ct[j-1] ^ (fb & ge[j]);

        ct[0]=fb;
    end

    if (bit_order=="NORMAL")
        co=ct;
    else begin
        for (i=0;i<CW;i=i+1)
            co[i]=ct[CW-1-i];
    end

    crc_f=co;
end

endfunction

  function [7:0] nextCRC8_D8;

    input [7:0] Data;
    input [7:0] CRC;
    input [63:0]bit_order;

    reg [7:0] D;
    reg [7:0] C;
    reg [7:0] NewCRC;

  begin

// convention: the first serial data bit is D[7]
//    D = Data;
    //   usually, our format is D[0] is first
    if(bit_order == "NORMAL")
        D = Data;
    else if(bit_order == "REVERSE")
        D = {Data[0],Data[1],Data[2],Data[3],Data[4],Data[5],Data[6],Data[7]};

//Mengyu    D = Data;
    C = CRC;

    NewCRC[0] = D[7] ^ D[6] ^ D[0] ^ C[0] ^ C[6] ^ C[7];
    NewCRC[1] = D[6] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[6];
    NewCRC[2] = D[6] ^ D[2] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[6];
    NewCRC[3] = D[7] ^ D[3] ^ D[2] ^ D[1] ^ C[1] ^ C[2] ^ C[3] ^ C[7];
    NewCRC[4] = D[4] ^ D[3] ^ D[2] ^ C[2] ^ C[3] ^ C[4];
    NewCRC[5] = D[5] ^ D[4] ^ D[3] ^ C[3] ^ C[4] ^ C[5];
    NewCRC[6] = D[6] ^ D[5] ^ D[4] ^ C[4] ^ C[5] ^ C[6];
    NewCRC[7] = D[7] ^ D[6] ^ D[5] ^ C[5] ^ C[6] ^ C[7];

    nextCRC8_D8 = NewCRC;

  end

  endfunction

  function [7:0] nextCRC8_D16;

    //  模块接口声明
    input   [15:0]  data_in;                        //[15:0] 输入数据
    input   [7:0]   crc_in;                         //[7:0] CRC初值/结果输入

    reg     [7:0]   crc_out;                        //[7:0] CRC计算结果


    begin

        crc_out[0] = data_in[15] ^ data_in[14] ^ data_in[11] ^ data_in[10] ^ data_in[9] ^ data_in[6] ^ data_in[4] ^ data_in[3] ^ data_in[0] ^
                                crc_in[7]  ^ crc_in[6] ^ crc_in[3] ^ crc_in[2] ^ crc_in[1];
        crc_out[1] = data_in[15] ^ data_in[12] ^ data_in[11] ^ data_in[10] ^ data_in[7] ^ data_in[5] ^ data_in[4] ^ data_in[1] ^
                    crc_in[7]  ^ crc_in[4] ^ crc_in[3] ^ crc_in[2];
        crc_out[2] = data_in[13] ^ data_in[12] ^ data_in[11] ^ data_in[8] ^ data_in[6] ^ data_in[5] ^ data_in[2] ^
                    crc_in[5]  ^ crc_in[4] ^ crc_in[3] ^ crc_in[0];
        crc_out[3] = data_in[14] ^ data_in[13] ^ data_in[12] ^ data_in[9] ^ data_in[7] ^ data_in[6] ^ data_in[3] ^
                    crc_in[6]  ^ crc_in[5] ^ crc_in[4] ^ crc_in[1];
        crc_out[4] = data_in[13] ^ data_in[11] ^ data_in[9] ^ data_in[8] ^ data_in[7] ^ data_in[6] ^ data_in[3] ^ data_in[0] ^
                    crc_in[5]  ^ crc_in[3] ^ crc_in[1] ^ crc_in[0];
        crc_out[5] = data_in[15] ^ data_in[12] ^ data_in[11] ^ data_in[8] ^ data_in[7] ^ data_in[6] ^ data_in[3] ^ data_in[1] ^ data_in[0] ^
                    crc_in[7]  ^ crc_in[4] ^ crc_in[3] ^ crc_in[0];
        crc_out[6] = data_in[13] ^ data_in[12] ^ data_in[9] ^ data_in[8] ^ data_in[7] ^ data_in[4] ^ data_in[2] ^ data_in[1] ^
                    crc_in[5]  ^ crc_in[4] ^ crc_in[1] ^ crc_in[0];
        crc_out[7] = data_in[14] ^ data_in[13] ^ data_in[10] ^ data_in[9] ^ data_in[8] ^ data_in[5] ^ data_in[3] ^ data_in[2] ^
                     crc_in[6]  ^ crc_in[5] ^ crc_in[2] ^ crc_in[1] ^ crc_in[0];

        nextCRC8_D16 = crc_out;

    end

    endfunction

    function [15:0] nextCRC16_D8;

    input       [7:0]   data_in ;
    input       [15:0]  crc_old ;

    reg         [15:0]  crc_new ;

//=============================================================================
    begin
        crc_new[0] = data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0] ^
                     crc_old[8] ^ crc_old[9] ^ crc_old[10] ^ crc_old[11] ^ crc_old[12] ^ crc_old[13] ^ crc_old[14] ^
                 crc_old[15];
        crc_new[1] = data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1] ^ crc_old[9] ^
               crc_old[10] ^ crc_old[11] ^ crc_old[12] ^ crc_old[13] ^ crc_old[14] ^ crc_old[15];
        crc_new[2] = data_in[1] ^ data_in[0] ^ crc_old[8] ^ crc_old[9];
        crc_new[3] = data_in[2] ^ data_in[1] ^ crc_old[9] ^ crc_old[10];
        crc_new[4] = data_in[3] ^ data_in[2] ^ crc_old[10] ^ crc_old[11];
        crc_new[5] = data_in[4] ^ data_in[3] ^ crc_old[11] ^ crc_old[12];
        crc_new[6] = data_in[5] ^ data_in[4] ^ crc_old[12] ^ crc_old[13];
        crc_new[7] = data_in[6] ^ data_in[5] ^ crc_old[13] ^ crc_old[14];
        crc_new[8] = data_in[7] ^ data_in[6] ^ crc_old[0] ^ crc_old[14] ^ crc_old[15];
        crc_new[9] = data_in[7] ^ crc_old[1] ^ crc_old[15];
        crc_new[10] = crc_old[2];
        crc_new[11] = crc_old[3];
        crc_new[12] = crc_old[4];
        crc_new[13] = crc_old[5];
        crc_new[14] = crc_old[6];
        crc_new[15] = data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0] ^
                      crc_old[7] ^ crc_old[8] ^ crc_old[9] ^ crc_old[10] ^ crc_old[11] ^ crc_old[12] ^ crc_old[13] ^
                      crc_old[14]^ crc_old[15];

        nextCRC16_D8 = crc_new;
    end

    endfunction


    function [31:0] nextCRC32_D16;

    input       [15:0]   data_in ;
    input       [31:0]   crc_old ;

    reg         [31:0]   crc_new ;

//=============================================================================
    begin
                crc_new[0] = crc_old[16] ^ crc_old[22] ^ crc_old[25] ^ crc_old[26] ^ crc_old[28] ^ data_in[0] ^ data_in[6] ^ data_in[9] ^ data_in[10] ^ data_in[12];
                crc_new[1] = crc_old[16] ^ crc_old[17] ^ crc_old[22] ^ crc_old[23] ^ crc_old[25] ^ crc_old[27] ^ crc_old[28] ^ crc_old[29] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[13];
                crc_new[2] = crc_old[16] ^ crc_old[17] ^ crc_old[18] ^ crc_old[22] ^ crc_old[23] ^ crc_old[24] ^ crc_old[25] ^ crc_old[29] ^ crc_old[30] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[13] ^ data_in[14];
                crc_new[3] = crc_old[17] ^ crc_old[18] ^ crc_old[19] ^ crc_old[23] ^ crc_old[24] ^ crc_old[25] ^ crc_old[26] ^ crc_old[30] ^ crc_old[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[14] ^ data_in[15];
                crc_new[4] = crc_old[16] ^ crc_old[18] ^ crc_old[19] ^ crc_old[20] ^ crc_old[22] ^ crc_old[24] ^ crc_old[27] ^ crc_old[28] ^ crc_old[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[8] ^ data_in[11] ^ data_in[12] ^ data_in[15];
                crc_new[5] = crc_old[16] ^ crc_old[17] ^ crc_old[19] ^ crc_old[20] ^ crc_old[21] ^ crc_old[22] ^ crc_old[23] ^ crc_old[26] ^ crc_old[29] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[13];
                crc_new[6] = crc_old[17] ^ crc_old[18] ^ crc_old[20] ^ crc_old[21] ^ crc_old[22] ^ crc_old[23] ^ crc_old[24] ^ crc_old[27] ^ crc_old[30] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[14];
                crc_new[7] = crc_old[16] ^ crc_old[18] ^ crc_old[19] ^ crc_old[21] ^ crc_old[23] ^ crc_old[24] ^ crc_old[26] ^ crc_old[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7] ^ data_in[8] ^ data_in[10] ^ data_in[15];
                crc_new[8] = crc_old[16] ^ crc_old[17] ^ crc_old[19] ^ crc_old[20] ^ crc_old[24] ^ crc_old[26] ^ crc_old[27] ^ crc_old[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[8] ^ data_in[10] ^ data_in[11] ^ data_in[12];
                crc_new[9] = crc_old[17] ^ crc_old[18] ^ crc_old[20] ^ crc_old[21] ^ crc_old[25] ^ crc_old[27] ^ crc_old[28] ^ crc_old[29] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[13];
                crc_new[10] = crc_old[16] ^ crc_old[18] ^ crc_old[19] ^ crc_old[21] ^ crc_old[25] ^ crc_old[29] ^ crc_old[30] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[9] ^ data_in[13] ^ data_in[14];
                crc_new[11] = crc_old[16] ^ crc_old[17] ^ crc_old[19] ^ crc_old[20] ^ crc_old[25] ^ crc_old[28] ^ crc_old[30] ^ crc_old[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[9] ^ data_in[12] ^ data_in[14] ^ data_in[15];
                crc_new[12] = crc_old[16] ^ crc_old[17] ^ crc_old[18] ^ crc_old[20] ^ crc_old[21] ^ crc_old[22] ^ crc_old[25] ^ crc_old[28] ^ crc_old[29] ^ crc_old[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[12] ^ data_in[13] ^ data_in[15];
                crc_new[13] = crc_old[17] ^ crc_old[18] ^ crc_old[19] ^ crc_old[21] ^ crc_old[22] ^ crc_old[23] ^ crc_old[26] ^ crc_old[29] ^ crc_old[30] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[13] ^ data_in[14];
                crc_new[14] = crc_old[18] ^ crc_old[19] ^ crc_old[20] ^ crc_old[22] ^ crc_old[23] ^ crc_old[24] ^ crc_old[27] ^ crc_old[30] ^ crc_old[31] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[14] ^ data_in[15];
                crc_new[15] = crc_old[19] ^ crc_old[20] ^ crc_old[21] ^ crc_old[23] ^ crc_old[24] ^ crc_old[25] ^ crc_old[28] ^ crc_old[31] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[12] ^ data_in[15];
                crc_new[16] = crc_old[0] ^ crc_old[16] ^ crc_old[20] ^ crc_old[21] ^ crc_old[24] ^ crc_old[28] ^ crc_old[29] ^ data_in[0] ^ data_in[4] ^ data_in[5] ^ data_in[8] ^ data_in[12] ^ data_in[13];
                crc_new[17] = crc_old[1] ^ crc_old[17] ^ crc_old[21] ^ crc_old[22] ^ crc_old[25] ^ crc_old[29] ^ crc_old[30] ^ data_in[1] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[13] ^ data_in[14];
                crc_new[18] = crc_old[2] ^ crc_old[18] ^ crc_old[22] ^ crc_old[23] ^ crc_old[26] ^ crc_old[30] ^ crc_old[31] ^ data_in[2] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[14] ^ data_in[15];
                crc_new[19] = crc_old[3] ^ crc_old[19] ^ crc_old[23] ^ crc_old[24] ^ crc_old[27] ^ crc_old[31] ^ data_in[3] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[15];
                crc_new[20] = crc_old[4] ^ crc_old[20] ^ crc_old[24] ^ crc_old[25] ^ crc_old[28] ^ data_in[4] ^ data_in[8] ^ data_in[9] ^ data_in[12];
                crc_new[21] = crc_old[5] ^ crc_old[21] ^ crc_old[25] ^ crc_old[26] ^ crc_old[29] ^ data_in[5] ^ data_in[9] ^ data_in[10] ^ data_in[13];
                crc_new[22] = crc_old[6] ^ crc_old[16] ^ crc_old[25] ^ crc_old[27] ^ crc_old[28] ^ crc_old[30] ^ data_in[0] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[14];
                crc_new[23] = crc_old[7] ^ crc_old[16] ^ crc_old[17] ^ crc_old[22] ^ crc_old[25] ^ crc_old[29] ^ crc_old[31] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[9] ^ data_in[13] ^ data_in[15];
                crc_new[24] = crc_old[8] ^ crc_old[17] ^ crc_old[18] ^ crc_old[23] ^ crc_old[26] ^ crc_old[30] ^ data_in[1] ^ data_in[2] ^ data_in[7] ^ data_in[10] ^ data_in[14];
                crc_new[25] = crc_old[9] ^ crc_old[18] ^ crc_old[19] ^ crc_old[24] ^ crc_old[27] ^ crc_old[31] ^ data_in[2] ^ data_in[3] ^ data_in[8] ^ data_in[11] ^ data_in[15];
                crc_new[26] = crc_old[10] ^ crc_old[16] ^ crc_old[19] ^ crc_old[20] ^ crc_old[22] ^ crc_old[26] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[10];
                crc_new[27] = crc_old[11] ^ crc_old[17] ^ crc_old[20] ^ crc_old[21] ^ crc_old[23] ^ crc_old[27] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7] ^ data_in[11];
                crc_new[28] = crc_old[12] ^ crc_old[18] ^ crc_old[21] ^ crc_old[22] ^ crc_old[24] ^ crc_old[28] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[8] ^ data_in[12];
                crc_new[29] = crc_old[13] ^ crc_old[19] ^ crc_old[22] ^ crc_old[23] ^ crc_old[25] ^ crc_old[29] ^ data_in[3] ^ data_in[6] ^ data_in[7] ^ data_in[9] ^ data_in[13];
                crc_new[30] = crc_old[14] ^ crc_old[20] ^ crc_old[23] ^ crc_old[24] ^ crc_old[26] ^ crc_old[30] ^ data_in[4] ^ data_in[7] ^ data_in[8] ^ data_in[10] ^ data_in[14];
                crc_new[31] = crc_old[15] ^ crc_old[21] ^ crc_old[24] ^ crc_old[25] ^ crc_old[27] ^ crc_old[31] ^ data_in[5] ^ data_in[8] ^ data_in[9] ^ data_in[11] ^ data_in[15];


        nextCRC32_D16 = crc_new;
    end

    endfunction
