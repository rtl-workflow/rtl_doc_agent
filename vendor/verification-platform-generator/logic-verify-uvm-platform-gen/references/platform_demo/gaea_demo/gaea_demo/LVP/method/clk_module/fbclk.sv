// ---------------------------------------------------------------------
//                  Logic Verification Latest
//                  =================================
// File			    : fbclk.sv
// Author		    : WangAoXiang w00574459
// Email            :   
// Created TIME		: Sept 25 2024
// VERSION          : 1.0
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef __FBCLK_SVH__
`define __FBCLK_SVH__ 

`ifndef __FB_PKG_SVH__
`timescale 1ns/1ps
`endif

//define fbclk

`define fb_clk_div(clk,clk_div,div)  \
initial begin \
    clk_div=1'b0; \
    @(posedge clk); \
    clk_div=1'b1; \
    forever begin \
        repeat(div) @(clk); \
        clk_div = ~clk_div; \
    end \
end 


`define fb_clk_gen(clk,frequency,ppm,phase)  \
class \_fbclk_``clk extends fbclk ; \
    virtual  task run(); \
         clk = 1'b0;  \
         start_rec(); \
         #m_standard; \
         end_rec();   \
         #m_standard; \
         while(m_half_period_base == 0) begin \
            #m_standard; \
         end \
         #(2.0*m_phase*m_half_period_base); \
         clk = 1'b1;  \
         forever begin \
           if (m_stop==1) begin \
               m_active=0; \
               m_stop=0; \
               return; \
           end \
           if (m_half_period_base == 0) begin \
               clk = 1'b0; \
               #m_standard; \
               continue; \
           end \
           if (m_c==0)  begin \
               #(m_half_period_base)  clk = ~clk; \
               continue; \
           end \
           m_cvalue = m_cvalue+m_c; \
           if (m_cvalue>=m_p)  begin \
               m_cvalue =m_cvalue-m_p; \
               #(m_half_period_max)  clk = ~clk; \
           end \
           else begin \
               #(m_half_period_base)  clk = ~clk; \
           end \
         end \
    endtask \
    function new(string name,real freq); \
        super.new(name,freq); \
        m_ppm=ppm; \
        m_phase=phase; \
        fork \
            this.start(); \
        join_none \
    endfunction \
endclass \
function string \``clk``_scope_ (); \
    string tmp; \
    int len; \
    $sformat(tmp,"%m"); \
    len=tmp.len(); \
    tmp = tmp.substr(0,len-8); \
    return tmp;\
endfunction \
\_fbclk_``clk   \``clk``_obj =new(\``clk``_scope_ (),frequency) 

`define fb_clk_setfreq(clk,freq)           \``clk``_obj .setfreq(freq) 
`define fb_clk_setppm(clk,ppm)             \``clk``_obj .setppm(ppm) 
`define fb_clk_setphase(clk,phase)         \``clk``_obj .setphase(phase) 
`define fb_clk_start(clk)                  \``clk``_obj .start() 
`define fb_clk_stop(clk)                   \``clk``_obj .stop() 


//add by s125255 beginning
`define fb_clk_gap_gen(clk,gap,clk_gap,frequency,ppm,phase,sigma_p,sigma_c) \
 class _fbclk_gap_``clk extends fbclk ; \
    virtual  task run(); \
        fork    \
            begin   \
                clk = 1'b0;  \
                start_rec(); \
                #m_standard; \
                end_rec();   \
                #m_standard; \
                while(m_half_period_base == 0) begin \
                   #m_standard; \
                end \
                #(2.0*m_phase*m_half_period_base); \
                clk = 1'b1;  \
                forever begin \
                  //if (m_stop==1) begin \
                  //    m_active=0; \
                  //    m_stop=0; \
                  //    return; \
                  //end \
                  if (m_half_period_base == 0) begin \
                      clk = 1'b0; \
                      #m_standard; \
                      continue; \
                  end \
                  if (m_c==0)  begin \
                      #(m_half_period_base)  clk = ~clk; \
                      continue; \
                  end \
                  m_cvalue = m_cvalue+m_c; \
                  if (m_cvalue>=m_p)  begin \
                      m_cvalue =m_cvalue-m_p; \
                      #(m_half_period_max)  clk = ~clk; \
                  end \
                  else begin \
                      #(m_half_period_base)  clk = ~clk; \
                  end \
                end \
            end \
            begin   \
                gap <= 1'b1; \
                @(posedge clk); \
                forever begin   \
                    m_sigma_result = m_sigma_c + m_sigma_remainer;  \
                    if (m_sigma_result < m_sigma_p) begin \
                        m_sigma_remainer = m_sigma_result;  \
                        gap <= 1'b1; \
                    end \
                    else begin  \
                        m_sigma_remainer = m_sigma_result - m_sigma_p;  \
                        gap <= 1'b0; \
                    end \
                    m_sigma_cnt += 1;   \
                    if (m_sigma_cnt == m_sigma_p) begin \
                        m_sigma_cnt = 0;    \
                        m_sigma_remainer = 0;   \
                    end \
                    @(posedge clk); \
                end \
            end \
            begin   \
                clk_gap = 1'b0; \
                forever begin   \
                    @(clk); \
                    if (gap == 1'b0)    \
                        clk_gap = clk;  \
                    else    \
                        clk_gap = 0;    \
                end \
            end \
        join_none   \
    endtask \
    function new(string name,real freq); \
        super.new(name,freq); \
        m_ppm=ppm; \
        m_phase=phase; \
        m_sigma_p=sigma_p;  \
        m_sigma_c=sigma_c;  \
        fork \
            this.start(); \
        join_none \
    endfunction \
endclass \
function string clk``_scope_(); \
    string tmp; \
    int len; \
    $sformat(tmp,"%m"); \
    len=tmp.len(); \
    tmp = tmp.substr(0,len-8); \
    return tmp;\
endfunction \
_fbclk_gap_``clk   clk``_gap_obj=new(clk``_scope_(),frequency)   

`define fb_clk_gap_setfreq(clk,freq)           clk``_gap_obj.setfreq(freq) 
`define fb_clk_gap_setppm(clk,ppm)             clk``_gap_obj.setppm(ppm) 
`define fb_clk_gap_setphase(clk,phase)         clk``_gap_obj.setphase(phase) 
`define fb_clk_gap_setgap(clk,sigma_p,sigma_c) clk``_gap_obj.setgap(sigma_p,sigma_c) 
`define fb_clk_gap_start(clk)                  clk``_gap_obj.start() 
`define fb_clk_gap_stop(clk)                   clk``_gap_obj.stop()


`define fb_clk_array_gen(clk,frequency,ppm,phase,clk_en)  \
class _fbclk_array_``clk;   \
    fbclk   m_fbclk[];  \
    bit     is_run; \
    function new(); \
        bit m_tmp[]; \
        m_tmp = clk; \
        m_fbclk = new[m_tmp.size];    \
        foreach(m_fbclk[i]) begin   \
            m_fbclk[i] = new($psprintf("clk[%0d]",i),frequency[i]); \
            m_fbclk[i].m_ppm = ppm[i];  \
            m_fbclk[i].m_phase = phase[i];  \
            m_fbclk[i].m_clk_en = clk_en[i];  \
        end \
        fork \
            this.run(); \
        join_none \
    endfunction \
    virtual  task run(); \
        if (is_run == 1'b1) return; \
        is_run = 1'b1; \
        for(int j=0; j<m_fbclk.size; j++) begin \
            automatic int i=j;  \
            fork \
                begin   \
                    m_fbclk[i].m_active = 1'b1; \
                    clk[i] = 1'b0;  \
                    m_fbclk[i].start_rec(); \
                    #m_fbclk[i].m_standard; \
                    m_fbclk[i].end_rec();   \
                    #m_fbclk[i].m_standard; \
                    while(m_fbclk[i].m_half_period_base == 0 || m_fbclk[i].m_clk_en == 0) begin \
                       #m_fbclk[i].m_standard; \
                    end \
                    #(2.0*m_fbclk[i].m_phase*m_fbclk[i].m_half_period_base); \
                    clk[i] = 1'b1;  \
                    forever begin \
                      if (m_fbclk[i].m_half_period_base == 0 || m_fbclk[i].m_clk_en == 0 ) begin \
                         clk[i] = 1'b0; \
                         #m_fbclk[i].m_standard; \
                         continue; \
                      end \
                      if (m_fbclk[i].m_c==0)  begin \
                          #(m_fbclk[i].m_half_period_base)  clk[i] = ~clk[i]; \
                          continue; \
                      end \
                      m_fbclk[i].m_cvalue = m_fbclk[i].m_cvalue+m_fbclk[i].m_c; \
                      if (m_fbclk[i].m_cvalue>=m_fbclk[i].m_p)  begin \
                          m_fbclk[i].m_cvalue =m_fbclk[i].m_cvalue-m_fbclk[i].m_p; \
                          #(m_fbclk[i].m_half_period_max)  clk[i] = ~clk[i]; \
                      end \
                      else begin \
                          #(m_fbclk[i].m_half_period_base)  clk[i] = ~clk[i]; \
                      end \
                    end \
                end \
            join_none   \
        end \
    endtask \
endclass \
_fbclk_array_``clk  clk``_array_obj=new()

`define fb_clk_array_setfreq(clk,freq)      foreach(clk``_array_obj.m_fbclk[i]) clk``_array_obj.m_fbclk[i].setfreq(freq[i]) 
`define fb_clk_array_setppm(clk,ppm)        foreach(clk``_array_obj.m_fbclk[i]) clk``_array_obj.m_fbclk[i].setppm(ppm[i])
`define fb_clk_array_setphase(clk,phase)    foreach(clk``_array_obj.m_fbclk[i]) clk``_array_obj.m_fbclk[i].setphase(phase[i])
`define fb_clk_array_setclken(clk,clk_en)   foreach(clk``_array_obj.m_fbclk[i]) clk``_array_obj.m_fbclk[i].setclken(clk_en[i])

`define fb_clk_array_one_setfreq(clk,freq,index)    clk``_array_obj.m_fbclk[index].setfreq(freq) 
`define fb_clk_array_one_setppm(clk,ppm,index)      clk``_array_obj.m_fbclk[index].setppm(ppm)
`define fb_clk_array_one_setphase(clk,phase,index)  clk``_array_obj.m_fbclk[index].setphase(phase)
`define fb_clk_array_one_setclken(clk,clk_en,index) clk``_array_obj.m_fbclk[index].setclken(clk_en)

`define fb_clk_array_start(clk)             clk``_array_obj.run()
//ending

typedef class fbclk;

class fbclk;
   //static fbclk  clkpool[string];
   //static fbclk  groupactive[string];
   real    m_percision; 
   real    m_unit; 
   real    m_freq;//0.001hz
   real    m_star_time;
   real    m_end_time;
   real    m_half_period_base;//0.001fs
   real    m_half_period_max;//0.001fs
   string  m_name_str;
   bit     m_enb;
   real    m_phase; //period
   bit     m_active;
   real    m_standard;
   bit     m_stop;
   longint unsigned  m_cvalue;
   longint unsigned  m_p;
   longint unsigned  m_c;
   longint signed  m_ppm;

   //add for gap gen by s125255
   longint unsigned  m_sigma_p;
   longint unsigned  m_sigma_c;
   longint unsigned  m_sigma_cnt;
   longint unsigned  m_sigma_remainer;
   longint unsigned  m_sigma_result;

   bit     m_clk_en;

   function new(string name,real freq);
       m_percision = 1;//1fs
       m_unit      = 1e6;//ns
       m_standard  = 1.111111;
       m_name_str  = name;
       m_enb       = 1;
       m_phase     = 0;
       m_ppm       = 0;
       m_active    = 0;
       m_stop      = 0;
       m_freq      = freq*1e6;//KHz
       m_p         = 0;
       m_c         = 0;
       m_clk_en    = 0;

       m_sigma_p   = 0;
       m_sigma_c   = 0;
       m_sigma_cnt = 0;
       m_sigma_remainer = 0;
       m_sigma_result   = 0;

   endfunction

   function void setfreq(real freq);//MHz
       m_freq = freq*1000000;
       if (m_active)  begin
           flush;
           $display(psdisplay());
       end
       
       return ;
   endfunction


   function void setppm(longint signed  ppm);
       longint signed  tmp_time;
       longint signed  tmp_time_ppm;
       m_ppm = ppm;
       if (m_active)  begin
           flush;
           $display(psdisplay());
       end
       return ;
   endfunction

   function void setphase(real phase);
       m_phase = phase;
       return ;
   endfunction

   function void setgap(real sigma_p,real sigma_c);
       m_sigma_p = sigma_p;
       m_sigma_c = sigma_c;
       return ;
   endfunction

   function void setclken(bit clk_en);
       m_clk_en = clk_en;
       return ;
   endfunction

   function void real2frac(real value,ref longint signed den,ref longint signed num);
       value = value*100;
       num = value; 
       den = 100;
       prime(den,num);
       return ;
   endfunction


   function void flush();
       longint signed  var_p,var_c;
       longint signed  var_time;
       longint signed  tmp;
       longint signed  var_period;
       longint signed  var_period_point;

       var_time = 1e15/(2*m_percision);

       real2frac(m_freq,var_p,var_c);
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

   function string psdisplay();
           $sformat(psdisplay, "************clk=%s*************\n",m_name_str);
           $sformat(psdisplay, "%sfrequency=%0f\n",psdisplay,m_freq);
           $sformat(psdisplay, "%shalf period=%0f,m_p=%0d,m_c=%0d \n",psdisplay,m_half_period_base,m_p,m_c);
           $sformat(psdisplay, "%sppm=%0d,phase=%0f\n",psdisplay,m_ppm,m_phase);
           $sformat(psdisplay, "%sunit=%0dfs,percision=%0dfs \n",psdisplay,m_unit,m_percision);
   endfunction

   task start();
        if ((m_stop ==1)&&(m_active==1))  begin
            wait(m_active==0);
        end

        if (m_active==1) begin
            return;
        end    
        m_active=1;

        fork  
            run();
        join_none 
   endtask

   task stop();
       if (m_active==0) begin
           return;
       end    
       m_stop=1;
   endtask


   virtual  task run();
   endtask

   static function void prime(ref longint signed  a,ref longint signed b);
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

    static function real simtime(string unit="fs");
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
            $display("Error:%s timescale error:",m_name_str);
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
        $display(psdisplay());
        m_standard = (2000000 - v_stand)*1.0/m_unit;

    endfunction





endclass


`endif





