// ---------------------------------------------------------------------
//                  Logic Verification Latest
//                  =================================
// File			    : god_clk.sv
// Author		    : WangAoXiang w00574459
// Email            :   
// Created TIME		: Sept 25 2024
// VERSION          : 1.0
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef GOD_TIME
`timescale 1ns/1fs
`endif


`define gd_clk_gen(clk_o,freq,ppm,phase,clk_en)  \
god_clk   \u_``clk_o ( \
    .clk            (clk_o          ), \
    .gap            (               ), \
    .clk_gap        (               ), \
    .m_freq         (freq           ), \
    .m_ppm          (ppm            ), \
    .m_phase        (phase          ), \
    .m_clk_en       (clk_en         ), \
    .m_gap_en       (1'b0           ), \
    .m_sigma_p      (64'h0          ), \
    .m_sigma_c      (64'h0          ));


`define gd_clk_gap_gen(clk_o,gap_o,clk_gap_o,freq,ppm,phase,sigma_p,sigma_c) \
god_clk   u_``clk_o ( \
    .clk            (clk_o          ), \
    .gap            (gap_o          ), \
    .clk_gap        (clk_gap_o      ), \
    .m_freq         (freq           ), \
    .m_ppm          (ppm            ), \
    .m_phase        (phase          ), \
    .m_clk_en       (1'b1           ), \
    .m_gap_en       (1'b1           ), \
    .m_sigma_p      (sigma_p        ), \
    .m_sigma_c      (sigma_c        ));


`define gd_clk_array_gen(clk_o,freq,ppm,phase,clk_en,size)  \
generate begin : clk_o``_array_gen \
    genvar  idx; \
    for(idx=0; idx<size; idx++) begin : clk_o``_array_proc \
        god_clk   u_``clk_o ( \
            .clk            (clk_o[idx]     ), \
            .gap            (               ), \
            .clk_gap        (               ), \
            .m_freq         (freq[idx]      ), \
            .m_ppm          (ppm[idx]       ), \
            .m_phase        (phase[idx]     ), \
            .m_clk_en       (clk_en[idx]    ), \
            .m_gap_en       (1'b0           ), \
            .m_sigma_p      (64'h0          ), \
            .m_sigma_c      (64'h0          )); \
    end \
end \
endgenerate \


module god_clk (
    output  bit                 clk,
    output  bit                 gap,
    output  bit                 clk_gap,
    input   real                m_freq,
    input   longint signed      m_ppm,
    input   real                m_phase,
    input   bit                 m_clk_en,
    input   bit                 m_gap_en,
    input   longint unsigned    m_sigma_p,
    input   longint unsigned    m_sigma_c);

real                m_percision; 
real                m_unit; 
real                m_star_time;
real                m_end_time;
real                m_half_period_base;//0.001fs
real                m_half_period_max;//0.001fs
real                m_standard;
longint unsigned    m_cvalue;
longint unsigned    m_p;
longint unsigned    m_c;
longint unsigned    m_sigma_cnt;
longint unsigned    m_sigma_remainer;
longint unsigned    m_sigma_result;

initial begin
    m_percision         = 1;//1fs
    m_unit              = 1e6;//ns
    m_standard          = 1.111111;
    m_p                 = 0;
    m_c                 = 0;
    m_sigma_cnt         = 0;
    m_sigma_remainer    = 0;
    m_sigma_result      = 0;
end

initial begin
    clk = 1'b0;
    start_rec();
    #m_standard;
    end_rec();
    #m_standard;
    while(m_half_period_base == 0 || m_clk_en == 0) begin
        #m_standard;
    end 
    #(2.0*m_phase*m_half_period_base);
    clk = 1'b1;
    forever begin
        if (m_half_period_base == 0 || m_clk_en == 0) begin
            clk = 1'b0;
            #m_standard;
            continue;
        end
        if (m_c==0)  begin
            #(m_half_period_base)  clk = ~clk;
            continue;
        end
        m_cvalue = m_cvalue+m_c;
        if (m_cvalue>=m_p)  begin
            m_cvalue =m_cvalue-m_p;
            #(m_half_period_max)  clk = ~clk;
        end
        else begin
            #(m_half_period_base)  clk = ~clk;
        end
    end 
end

initial begin
    gap = 1'b1;
    clk_gap = 1'b0;
end

always @(posedge clk) begin
    if (m_gap_en == 1'b1) begin
        m_sigma_result = m_sigma_c + m_sigma_remainer;

        if (m_sigma_result < m_sigma_p) begin
            m_sigma_remainer = m_sigma_result;
            gap <= 1'b1;
        end
        else begin
            m_sigma_remainer = m_sigma_result - m_sigma_p;
            gap <= 1'b0;
        end
        m_sigma_cnt += 1;
        if (m_sigma_cnt >= m_sigma_p) begin
            m_sigma_cnt = 0;
            m_sigma_remainer = 0;
        end
    end
end

always @(clk) begin
    if (m_gap_en == 1'b1) begin
        if (gap == 1'b0)
            clk_gap = clk;
        else
            clk_gap = 0;
    end
end

always @ (m_freq or m_ppm) begin
    flush;
end

function automatic void prime(ref longint signed  a,ref longint signed b);
    longint unsigned num1,num2,temp;
    num1=a;
    num2=b;
    while (num2 !=0) begin
        temp = num1%num2;
        num1=num2;
        num2=temp;
    end
    a=a/num1;
    b=b/num1;
    return;
endfunction

function real simtime(string unit="fs");
    real   pow;
    string str;
    real   rvalue;
    int  relsult;
    case (unit)
        "fs":    pow =1.0;
        "ps":    pow =1.0e3;
        "ns":    pow =1.0e6;
        "us":    pow =1.0e9;
        "ms":    pow =1.0e12;
        "s":     pow =1.0e15;
        "m":     pow =6.0e16;
        "h":     pow =3.6e18;
        default  pow = -1000;
    endcase
    if (pow < 0)  begin
        return pow;
    end
    $timeformat(-15,0,"fs",30);
    $sformat(str,"%t",$realtime);
    relsult=$sscanf(str,"%f",rvalue);
    rvalue = rvalue/pow;
    return rvalue;
endfunction

function void start_rec();
    m_star_time = simtime();  
endfunction

function void end_rec();
    longint unsigned  v_stand;

    m_end_time = simtime();  
    v_stand = (m_end_time-m_star_time);

    //$display("v_stand=%0d",v_stand);

    if ((v_stand==0)|(v_stand>=10000000)) begin
        $display("unit/percision must be 1ns/100ps/10ps/1ps/100fs/10fs/1fs");
        $finish;
        return;
    end
    
    if (v_stand>=1000000)      m_unit=1e6;//ns
    else if (v_stand>=100000)  m_unit=1e5;//100ps
    else if (v_stand>=10000)   m_unit=1e4;//10ps
    else if (v_stand>=1000)    m_unit=1e3;//ps
    else if (v_stand>=100)     m_unit=1e2;//100fs
    else if (v_stand>=10)      m_unit=1e1;//10fs
    else if (v_stand>=1)       m_unit=1;//fs

    if ((v_stand%10)!=0)            m_percision=1;//fs
    else if ((v_stand%100)!=0)      m_percision=1e1;//10fs
    else if ((v_stand%1000)!=0)     m_percision=1e2;//100fs
    else if ((v_stand%10000)!=0)    m_percision=1e3;//1ps
    else if ((v_stand%100000)!=0)   m_percision=1e4;//10ps
    else if ((v_stand%1000000)!=0)  m_percision=1e5;//100ps
    else if ((v_stand%10000000)!=0) m_percision=1e6;//1ns

    //$display("m_percision=%0d",m_percision);

    //flush argument
    flush;
    m_standard = (2000000 - v_stand)*1.0/m_unit;

endfunction

function void flush();
    longint signed  var_p,var_c;
    longint signed  var_time;
    longint signed  tmp;
    longint signed  var_period;
    longint signed  var_period_point;

    var_time = 1e15/(2*m_percision);

    real2frac(m_freq*1e6,var_p,var_c);
    tmp = var_p;
    var_p=var_c;   
    var_c=(var_time/1e6)*(1e6-m_ppm)*tmp;


    var_period=var_c/var_p;
    var_period_point=var_c%var_p;
    prime(var_p,var_period_point);

    m_p= var_p;
    m_c= var_period_point;

    m_half_period_base = (1.0*var_period*m_percision)/m_unit;
    m_half_period_max  = (1.0*(var_period+1)*m_percision)/m_unit;
    m_cvalue = 0;

    return ;
endfunction

function automatic void real2frac(real value,ref longint signed den,ref longint signed num);
    value = value*100;
    num = value; 
    den = 100;
    prime(den,num);
    return ;
endfunction

endmodule
// ---------------------------------------------------------------------
// Modification History
// $Log$
// VERSION : Latest
// USER    : s125255
// TIME    : 2014-05-14 15:08
// LOG     : modify gd_clk_gen for generate

// VERSION : r140
// USER    : s00125255
// TIME    : 2014-05-14
// LOG     : modify clk to clk_o

// VERSION : r139
// USER    : s00125255
// TIME    : 2014-05-14
// LOG     : Creat
